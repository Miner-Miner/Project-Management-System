import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordHelper {
  static String hash(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  static bool verify(String inputPassword, String storedHash) {
    return hash(inputPassword) == storedHash;
  }
}
