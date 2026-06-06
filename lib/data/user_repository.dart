import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';

import '../models/user_model.dart';
import 'app_database.dart';
import 'supabase_remote_repository.dart';

class RegistrationResult {
  const RegistrationResult({
    required this.user,
    required this.requiresEmailConfirmation,
  });

  final UserModel user;
  final bool requiresEmailConfirmation;
}

class UserRepository {
  UserRepository({SupabaseRemoteRepository? remote})
      : _remote = remote ?? SupabaseRemoteRepository();

  final SupabaseRemoteRepository _remote;

  Future<UserModel?> findByEmail(String email) async {
    final db = await AppDatabase.instance();
    final rows = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [email.toLowerCase()],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  Future<UserModel?> authenticate({
    required String email,
    required String password,
  }) async {
    final remoteUser = await _remote.signIn(email: email, password: password);
    return _saveRemoteUser(
      remoteUser.copyWith(password: _hashPassword(email, password)),
    );
  }

  Future<UserModel?> restoreAuthenticatedUser() async {
    final remoteUser = await _remote.currentAuthenticatedUser();
    if (remoteUser == null) return null;
    return _saveRemoteUser(remoteUser);
  }

  Future<UserModel> _saveRemoteUser(UserModel remoteUser) async {
    final userToSave = remoteUser;
    try {
      final db = await AppDatabase.instance();
      final rows = await db.query(
        'users',
        where: 'LOWER(email) = ?',
        whereArgs: [userToSave.email.toLowerCase()],
        limit: 1,
      );

      if (rows.isEmpty) {
        return create(userToSave);
      }

      final user = UserModel.fromMap(rows.first);
      final updated = user.copyWith(
        name: userToSave.name,
        email: userToSave.email,
        password: userToSave.password.isNotEmpty
            ? userToSave.password
            : user.password,
        supabaseId: userToSave.supabaseId,
      );
      await update(updated);
      return updated;
    } catch (error) {
      if (!AppDatabase.isRecoverableWebDatabaseError(error)) {
        rethrow;
      }

      return userToSave.copyWith(id: _stableLocalUserId(userToSave));
    }
  }

  Future<UserModel> create(UserModel user) async {
    final db = await AppDatabase.instance();
    final id = await db.insert(
      'users',
      user.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return user.copyWith(id: id);
  }

  Future<RegistrationResult> register(UserModel user) async {
    final remoteResult = await _remote.signUp(user);
    final localUser = remoteResult.user.copyWith(
      password: _hashPassword(user.email, user.password),
    );

    final cachedUser = await _saveRemoteUser(localUser);

    return RegistrationResult(
      user: cachedUser,
      requiresEmailConfirmation: remoteResult.requiresEmailConfirmation,
    );
  }

  Future<void> update(UserModel user) async {
    final db = await AppDatabase.instance();
    await db.update(
      'users',
      user.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<UserModel> updateProfileName({
    required UserModel user,
    required String name,
  }) async {
    final updated = user.copyWith(name: name.trim());

    if (updated.supabaseId != null) {
      try {
        await _remote.updateProfileName(
          supabaseId: updated.supabaseId!,
          name: updated.name,
          email: updated.email,
        );
      } catch (_) {}
    }

    try {
      await update(updated);
    } catch (error) {
      if (!AppDatabase.isRecoverableWebDatabaseError(error)) {
        rethrow;
      }
    }

    return updated;
  }

  Future<void> signOut() => _remote.signOut();

  String _hashPassword(String email, String password) {
    final normalizedEmail = email.trim().toLowerCase();
    final bytes = utf8.encode('$normalizedEmail:$password');
    return sha256.convert(bytes).toString();
  }

  int _stableLocalUserId(UserModel user) {
    final source = user.supabaseId ?? user.email;
    var hash = 0;
    for (final codeUnit in source.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }
}
