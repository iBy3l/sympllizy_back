import 'package:sympllizy_back/core/core.dart';

abstract class AuthRepository {
  Future<Map<String, dynamic>?> findUserByEmail(String email);

  Future<Map<String, dynamic>> createOrg(DatabaseConnection db, String name, String slug);

  Future<Map<String, dynamic>> createUser(DatabaseConnection db, String email, String passwordHash);

  Future<void> createUserProfile(DatabaseConnection db, String userId, String? fullName);

  Future<void> addUserToOrg(DatabaseConnection db, {required String userId, required String orgId, String role});

  Future<Map<String, dynamic>> createDefaultCompany(DatabaseConnection db, String orgId);

  Future<Map<String, dynamic>> findPrimaryOrgByUser(String userId);
  Future<List<String>> findUserRoles(String userId, String orgId);

  Future<bool> findRefreshToken(DatabaseConnection tx, {required String userId, required String token});

  Future<void> revokeRefreshToken(DatabaseConnection tx, String token);

  Future<void> saveRefreshToken(DatabaseConnection tx, {required String userId, required String token, required DateTime expiresAt});

  Future<void> revokeAllRefreshTokens(DatabaseConnection tx, String userId);
}

class AuthRepositoryImpl implements AuthRepository {
  final DatabaseConnection _db; // para operações fora de tx (ex: findUserByEmail)

  AuthRepositoryImpl(this._db);

  // SQL constantes
  static const String selectUserByEmail = 'SELECT * FROM auth.users WHERE email = \$1 LIMIT 1';

  static const String insertOrg = '''
    INSERT INTO data.orgs (name, slug)
    VALUES (\$1, \$2)
    RETURNING id, name, slug
  ''';

  static const String insertUser = '''
    INSERT INTO auth.users (email, password_hash, is_active)
    VALUES (\$1, \$2, true)
    RETURNING id, email, created_at
  ''';

  static const String insertUserProfile = '''
    INSERT INTO data.user_profiles (user_id, full_name)
    VALUES (\$1, \$2)
  ''';

  static const String insertUserToOrg = '''
    INSERT INTO data.org_users (user_id, org_id, role)
    VALUES (\$1, \$2, \$3)
  ''';

  static const String insertDefaultCompany = '''
    INSERT INTO data.companies (org_id, name)
    VALUES (\$1, 'Matriz')
    RETURNING id, name
  ''';

  static const String insertRefreshToken = '''
    INSERT INTO auth.refresh_tokens (user_id, token, expires_at)
    VALUES (\$1, \$2, \$3)
  ''';
  static const String selectPrimaryOrg = '''
  SELECT o.id, o.name, o.slug
  FROM data.orgs o
  JOIN data.org_users ou ON ou.org_id = o.id
  WHERE ou.user_id = \$1
  ORDER BY ou.created_at
  LIMIT 1
''';

  static const String selectRoles = '''
  SELECT role
  FROM data.org_users
  WHERE user_id = \$1 AND org_id = \$2
''';

  static const String selectRefreshToken = '''
SELECT 1
FROM auth.refresh_tokens
WHERE user_id = \$1
  AND token = \$2
  AND revoked_at IS NULL
  AND expires_at > NOW()
LIMIT 1
''';

  static const String revokeRefreshTokenSql = '''
UPDATE auth.refresh_tokens
SET revoked_at = NOW()
WHERE token = \$1
''';
  static const String revokeAllRefreshTokensSql = '''
UPDATE auth.refresh_tokens
SET revoked_at = NOW()
WHERE user_id = \$1
  AND revoked_at IS NULL
''';

  @override
  Future<void> revokeAllRefreshTokens(DatabaseConnection tx, String userId) async {
    await tx.execute(revokeAllRefreshTokensSql, [userId]);
  }

  @override
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    final result = await _db.query(selectUserByEmail, [email]);
    if (result.isEmpty) return null;
    return result.first;
  }

  @override
  Future<Map<String, dynamic>> createOrg(DatabaseConnection db, String name, String slug) async {
    final rows = await db.query(insertOrg, [name, slug]);
    return rows.first;
  }

  @override
  Future<Map<String, dynamic>> createUser(DatabaseConnection db, String email, String passwordHash) async {
    final rows = await db.query(insertUser, [email, passwordHash]);
    return rows.first;
  }

  @override
  Future<void> createUserProfile(DatabaseConnection db, String userId, String? fullName) async {
    await db.execute(insertUserProfile, [userId, fullName]);
  }

  @override
  Future<void> addUserToOrg(DatabaseConnection db, {required String userId, required String orgId, String role = 'owner'}) async {
    await db.execute(insertUserToOrg, [userId, orgId, role]);
  }

  @override
  Future<Map<String, dynamic>> createDefaultCompany(DatabaseConnection db, String orgId) async {
    final rows = await db.query(insertDefaultCompany, [orgId]);
    return rows.first;
  }

  @override
  Future<Map<String, dynamic>> findPrimaryOrgByUser(String userId) async {
    final rows = await _db.query(selectPrimaryOrg, [userId]);
    if (rows.isEmpty) {
      throw ForbiddenException('Usuário sem organização');
    }
    return rows.first;
  }

  @override
  Future<List<String>> findUserRoles(String userId, String orgId) async {
    final rows = await _db.query(selectRoles, [userId, orgId]);
    return rows.map((e) => e['role'].toString()).toList();
  }

  @override
  Future<bool> findRefreshToken(DatabaseConnection tx, {required String userId, required String token}) async {
    final rows = await tx.query(selectRefreshToken, [userId, token]);

    return rows.isNotEmpty;
  }

  @override
  Future<void> revokeRefreshToken(DatabaseConnection tx, String token) async {
    await tx.execute(revokeRefreshTokenSql, [token]);
  }

  @override
  Future<void> saveRefreshToken(DatabaseConnection tx, {required String userId, required String token, required DateTime expiresAt}) async {
    await tx.execute(insertRefreshToken, [userId, token, expiresAt.toUtc()]);
  }
}
