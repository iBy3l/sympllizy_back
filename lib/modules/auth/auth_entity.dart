import 'package:sympllizy_back/core/core.dart';

class AuthEntity {
  final String userId;
  final String email;
  final String? fullName;
  final OrgEntity org;
  final CompanyEntity company;
  final TokenPair tokens;

  AuthEntity({required this.userId, required this.email, this.fullName, required this.org, required this.company, required this.tokens});

  factory AuthEntity.fromMap(Map<String, dynamic> map) {
    return AuthEntity(
      userId: map['user']['id'] as String,
      email: map['user']['email'] as String,
      fullName: map['user']['full_name'] as String?,
      org: OrgEntity.fromMap(map['org'] as Map<String, dynamic>),
      company: CompanyEntity.fromMap(map['company'] as Map<String, dynamic>),
      tokens: TokenPair(
        accessToken: map['access_token'] as String,
        refreshToken: map['refresh_token'] as String,
        accessExpiresAt: map['access_expires_at'] as int,
        refreshExpiresAt: map['refresh_expires_at'] as int,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'access_token': tokens.accessToken,
      'refresh_token': tokens.refreshToken,
      'access_expires_at': tokens.accessExpiresAt,
      'refresh_expires_at': tokens.refreshExpiresAt,
      'user': {
        'id': userId,
        'email': email,
        'full_name': fullName,
        'roles': ['owner'],
      },
      'org': org.toMap(),
      'company': company.toMap(),
    };
  }
}

class CompanyEntity {
  final String id;
  final String name;

  CompanyEntity({required this.id, required this.name});

  factory CompanyEntity.fromMap(Map<String, dynamic> map) {
    return CompanyEntity(id: map['id'] as String, name: map['name'] as String);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }
}

class OrgEntity {
  final String id;
  final String name;
  final String slug;

  OrgEntity({required this.id, required this.name, required this.slug});

  factory OrgEntity.fromMap(Map<String, dynamic> map) {
    return OrgEntity(id: map['id'] as String, name: map['name'] as String, slug: map['slug'] as String);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'slug': slug};
  }
}
