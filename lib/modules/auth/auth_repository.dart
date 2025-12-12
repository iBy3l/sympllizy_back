import 'package:sympllizy_back/core/core.dart';

abstract class AuthRepository {
  Future<Map<String, dynamic>?> findUserByEmail(String email);

  Future<Map<String, dynamic>> createOrg(DatabaseConnection db, String name, String slug);

  Future<Map<String, dynamic>> createUser(DatabaseConnection db, String email, String passwordHash);

  Future<void> createUserProfile(DatabaseConnection db, String userId, String? fullName);

  Future<void> addUserToOrg(DatabaseConnection db, {required String userId, required String orgId, String role});

  Future<Map<String, dynamic>> createDefaultCompany(DatabaseConnection db, String orgId);

  Future<void> saveRefreshToken(DatabaseConnection db, {required String userId, required String token, required DateTime expiresAt});
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
  Future<void> saveRefreshToken(DatabaseConnection db, {required String userId, required String token, required DateTime expiresAt}) async {
    await db.execute(insertRefreshToken, [userId, token, expiresAt.toUtc()]);
  }
}
