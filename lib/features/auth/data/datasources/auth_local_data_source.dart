import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthLocalDataSource {
  Future<UserEntity> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<UserEntity> signIn({required String email, required String password});

  Future<UserEntity?> getCurrentUser();

  Future<void> signOut();
}

/// Stores accounts in SharedPreferences on the device.
///
/// IMPORTANT: this is a demo implementation. The password is stored as a
/// salted SHA-256 hash, but the data lives on the device, not on a
/// server. In a real product password hashing (bcrypt/argon2) must
/// happen on the backend.
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;
  final Random _random = Random.secure();

  static const _usersKey = 'auth_users';
  static const _sessionKey = 'auth_session_user_id';

  @override
  Future<UserEntity> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final users = _readUsers();
    final normalizedEmail = email.trim().toLowerCase();

    if (users.any((u) => u.email == normalizedEmail)) {
      throw AuthException('Аккаунт с таким email уже существует');
    }

    final salt = _generateSalt();
    final user = _StoredUser(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      email: normalizedEmail,
      salt: salt,
      passwordHash: _hash(password, salt),
    );

    await _writeUsers([...users, user]);
    await _prefs.setString(_sessionKey, user.id);
    return user.toEntity();
  }

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final matches = _readUsers().where((u) => u.email == normalizedEmail);

    // The same message for "no such email" and "wrong password", so we
    // don't reveal which addresses are registered.
    if (matches.isEmpty) throw AuthException('Неверный email или пароль');
    final user = matches.first;
    if (user.passwordHash != _hash(password, user.salt)) {
      throw AuthException('Неверный email или пароль');
    }

    await _prefs.setString(_sessionKey, user.id);
    return user.toEntity();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final sessionId = _prefs.getString(_sessionKey);
    if (sessionId == null) return null;

    for (final user in _readUsers()) {
      if (user.id == sessionId) return user.toEntity();
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    await _prefs.remove(_sessionKey);
  }

  List<_StoredUser> _readUsers() {
    final raw = _prefs.getString(_usersKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => _StoredUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _writeUsers(List<_StoredUser> users) {
    return _prefs.setString(
      _usersKey,
      jsonEncode(users.map((u) => u.toJson()).toList()),
    );
  }

  String _generateSalt() =>
      base64UrlEncode(List<int>.generate(16, (_) => _random.nextInt(256)));

  String _hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();
}

class _StoredUser {
  const _StoredUser({
    required this.id,
    required this.name,
    required this.email,
    required this.salt,
    required this.passwordHash,
  });

  factory _StoredUser.fromJson(Map<String, dynamic> json) => _StoredUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        salt: json['salt'] as String,
        passwordHash: json['passwordHash'] as String,
      );

  final String id;
  final String name;
  final String email;
  final String salt;
  final String passwordHash;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'salt': salt,
        'passwordHash': passwordHash,
      };

  UserEntity toEntity() => UserEntity(id: id, name: name, email: email);
}
