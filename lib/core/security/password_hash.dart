import 'dart:convert';

import 'package:crypto/crypto.dart';

class PasswordHasher {
  const PasswordHasher();

  String hash(String password) {
    // Futuro: adicionar salt/pepper
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool verify(String password, String hashValue) {
    return hash(password) == hashValue;
  }
}
