import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/user_role.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _roleKey = 'user_role';
  static const String _phoneKey = 'phone_number';

  final FlutterSecureStorage _storage;

  Future<void> saveSession({
    required String token,
    required UserRole role,
    required String phoneNumber,
  }) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: token),
      _storage.write(key: _roleKey, value: role.nameValue),
      _storage.write(key: _phoneKey, value: phoneNumber),
    ]);
  }

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<UserRole?> readRole() async {
    final value = await _storage.read(key: _roleKey);
    if (value == null) return null;
    return UserRoleParsing.fromString(value);
  }

  Future<String?> readPhoneNumber() => _storage.read(key: _phoneKey);

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _roleKey),
      _storage.delete(key: _phoneKey),
    ]);
  }
}
