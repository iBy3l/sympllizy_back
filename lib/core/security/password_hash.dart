import 'package:bcrypt/bcrypt.dart';

class PasswordHash {
  const PasswordHash._();

  static String hash(String plainPassword) {
    if (plainPassword.isEmpty) {
      throw ArgumentError('Senha não pode ser vazia');
    }
    return BCrypt.hashpw(plainPassword, BCrypt.gensalt());
  }

  static bool verify(String plainPassword, String passwordHash) {
    if (plainPassword.isEmpty || passwordHash.isEmpty) {
      return false;
    }
    return BCrypt.checkpw(plainPassword, passwordHash);
  }
}
