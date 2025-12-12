import 'package:sympllizy_back/core/core.dart';

import 'auth_entity.dart';
import 'auth_repository.dart';

abstract class AuthService {
  Future<AuthEntity> signup({required String orgName, required String email, required String password, String? fullName});
}

class AuthServiceImpl implements AuthService {
  final DatabaseConnection _db;
  final AuthRepository _repo;
  final JwtService _jwt;
  final PasswordHasher _hasher;

  AuthServiceImpl(this._repo, this._db, this._jwt, this._hasher);

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
}
