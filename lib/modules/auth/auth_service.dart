import 'package:sympllizy_back/core/core.dart';

import 'auth_entity.dart';
import 'auth_repository.dart';

abstract class AuthService {
  Future<AuthEntity> signup({required String orgName, required String email, required String password, String? fullName});
  Future<Map<String, dynamic>> login({required String email, required String password});
  Future<Map<String, dynamic>> refresh(String refreshToken);
  Future<void> logout(String refreshToken);
  Future<void> logoutAll({required String userId});
}

class AuthServiceImpl implements AuthService {
  final DatabaseConnection _db;
  final AuthRepository _repo;
  final JwtService _jwt;
  final PasswordHasher _hasher;
  final Logger _logger;

  AuthServiceImpl(this._repo, this._db, this._jwt, this._hasher, this._logger);

  String _slugify(String value) {
    final lower = value.trim().toLowerCase();
    final slug = lower.replaceAll(RegExp(r'[^a-z0-9\s-]'), '').replaceAll(RegExp(r'\s+'), '-').replaceAll(RegExp(r'-+'), '-');
    return slug.isEmpty ? 'org' : slug;
  }

  @override
  Future<AuthEntity> signup({required String orgName, required String email, required String password, String? fullName}) async {
    // validações básicas
    if (orgName.trim().length < 3) {
      throw ValidationException('Nome da organização muito curto', details: {'org_name': 'min 3 caracteres'});
    }

    if (!email.contains('@')) {
      throw ValidationException('E-mail inválido', details: {'email': 'formato inválido'});
    }

    if (password.length < 6) {
      throw ValidationException('Senha muito curta', details: {'password': 'min 6 caracteres'});
    }

    // checa se user já existe (fora da tx mesmo)
    final existing = await _repo.findUserByEmail(email);
    if (existing != null) {
      throw ValidationException('E-mail já está em uso', details: {'email': 'já cadastrado'});
    }

    final slug = _slugify(orgName);
    final passwordHash = _hasher.hash(password);

    // 🔥 Agora sim: tudo que é crítico vai dentro de 1 transação
    return await _db.transaction((tx) async {
      final org = await _repo.createOrg(tx, orgName, slug);
      final orgId = org['id'].toString();

      final user = await _repo.createUser(tx, email, passwordHash);
      final userId = user['id'].toString();

      await _repo.createUserProfile(tx, userId, fullName);

      await _repo.addUserToOrg(tx, userId: userId, orgId: orgId, role: 'owner');

      final company = await _repo.createDefaultCompany(tx, orgId);

      final tokens = _jwt.generateTokens(userId: userId, orgId: orgId, roles: const ['owner']);

      await _repo.saveRefreshToken(tx, userId: userId, token: tokens.refreshToken, expiresAt: DateTime.fromMillisecondsSinceEpoch(tokens.refreshExpiresAt * 1000, isUtc: true));

      return AuthEntity(
        userId: userId,
        email: email,
        fullName: fullName,
        org: OrgEntity(id: orgId, name: org['name'] as String, slug: org['slug'] as String),
        company: CompanyEntity(id: company['id'].toString(), name: company['name'] as String),
        tokens: tokens,
      );
    });
  }

  @override
  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final user = await _repo.findUserByEmail(email);
    if (user == null) {
      throw UnauthorizedException('Credenciais inválidas');
    }

    final isValid = _hasher.verify(password, user['password_hash']);
    if (!isValid) {
      throw UnauthorizedException('Credenciais inválidas');
    }

    final userId = user['id'].toString();
    final org = await _repo.findPrimaryOrgByUser(userId);
    final orgId = org['id'].toString();
    final roles = await _repo.findUserRoles(userId, orgId);

    final tokens = _jwt.generateTokens(userId: userId, orgId: orgId, roles: roles);

    await _db.transaction((tx) async {
      await _repo.saveRefreshToken(tx, userId: userId, token: tokens.refreshToken, expiresAt: DateTime.fromMillisecondsSinceEpoch(tokens.refreshExpiresAt * 1000, isUtc: true));
    });

    return {
      'access_token': tokens.accessToken,
      'refresh_token': tokens.refreshToken,
      'access_expires_at': tokens.accessExpiresAt,
      'refresh_expires_at': tokens.refreshExpiresAt,
      'user': {'id': userId, 'email': email, 'roles': roles},
      'org': {'id': orgId, 'name': org['name'], 'slug': org['slug']},
    };
  }

  @override
  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    // 1️⃣ Verifica JWT
    final jwt = _jwt.verifyRefreshToken(refreshToken);

    final userId = _jwt.getUserId(jwt);
    final orgId = _jwt.getOrgId(jwt);

    if (userId.isEmpty || orgId.isEmpty) {
      throw UnauthorizedException('Token inválido');
    }

    // 2️⃣ Transação REAL
    return await _db.transaction((tx) async {
      final exists = await _repo.findRefreshToken(tx, userId: userId, token: refreshToken);

      if (!exists) {
        throw UnauthorizedException('Refresh token inválido ou revogado');
      }

      // 3️⃣ Gera novos tokens
      final tokens = _jwt.generateTokens(userId: userId, orgId: orgId, roles: const []);

      // 4️⃣ Revoga o antigo
      await _repo.revokeRefreshToken(tx, refreshToken);

      // 5️⃣ Salva o novo
      await _repo.saveRefreshToken(tx, userId: userId, token: tokens.refreshToken, expiresAt: DateTime.fromMillisecondsSinceEpoch(tokens.refreshExpiresAt * 1000, isUtc: true));

      return {'access_token': tokens.accessToken, 'refresh_token': tokens.refreshToken, 'access_expires_at': tokens.accessExpiresAt, 'refresh_expires_at': tokens.refreshExpiresAt};
    });
  }

  @override
  Future<void> logout(String refreshToken) async {
    // 1️⃣ Verifica JWT
    final jwt = _jwt.verifyRefreshToken(refreshToken);

    final userId = _jwt.getUserId(jwt);
    if (userId.isEmpty) {
      throw UnauthorizedException('Token inválido');
    }

    // 2️⃣ Revoga dentro de transação
    await _db.transaction((tx) async {
      final exists = await _repo.findRefreshToken(tx, userId: userId, token: refreshToken);

      if (!exists) {
        throw UnauthorizedException('Refresh token inválido ou já revogado');
      }

      await _repo.revokeRefreshToken(tx, refreshToken);
    });
  }

  @override
  Future<void> logoutAll({required String userId}) async {
    await _db.transaction((tx) async {
      _logger.info('auth.logout.global', 'Logout global realizado', context: {'user_id': userId});

      await _repo.revokeAllRefreshTokens(tx, userId);
    });
  }
}
