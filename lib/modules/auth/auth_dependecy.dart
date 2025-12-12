import 'package:sympllizy_back/modules/auth/auth_controller.dart';
import 'package:sympllizy_back/modules/auth/auth_repository.dart';
import 'package:sympllizy_back/modules/auth/auth_routes.dart';
import 'package:sympllizy_back/modules/auth/auth_service.dart';

import '../../core/core.dart';

AuthRoutes authDependency({required DatabaseConnection db, required JwtService jwtService, required PasswordHasher hasher}) {
  final authRepository = AuthRepositoryImpl(db);
  final authService = AuthServiceImpl(authRepository, db, jwtService, hasher);
  final authController = AuthController(authService);
  return AuthRoutes(authController);
}
