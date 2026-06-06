import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/transaction_model.dart';
import '../models/user_model.dart';
import 'supabase_config.dart';

class SupabaseSignUpResult {
  const SupabaseSignUpResult({
    required this.user,
    required this.requiresEmailConfirmation,
  });

  final UserModel user;
  final bool requiresEmailConfirmation;
}

class SupabaseRemoteRepository {
  bool get isEnabled => SupabaseConfig.isConfigured;

  SupabaseClient? get _client {
    if (!isEnabled) return null;
    return Supabase.instance.client;
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('Supabase não configurado.');
    }

    return _doSignIn(client, email: email, password: password);
  }

  Future<UserModel> _doSignIn(
    SupabaseClient client, {
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) throw const AuthException('Usuário não encontrado.');

    return _buildUserModel(
      client,
      supabaseUser: user,
      email: email,
      password: password,
    );
  }

  Future<UserModel> _buildUserModel(
    SupabaseClient client, {
    required User supabaseUser,
    required String email,
    required String password,
  }) async {
    final profile = await _loadProfileSafely(supabaseUser.id);
    final name = profile?['name'] as String? ??
        supabaseUser.userMetadata?['name'] as String? ??
        email.split('@').first;

    try {
      await upsertProfile(
        supabaseId: supabaseUser.id,
        name: name,
        email: email,
      );
    } catch (_) {}

    return UserModel(
      name: name,
      email: email,
      password: password,
      supabaseId: supabaseUser.id,
    );
  }

  Future<SupabaseSignUpResult> signUp(UserModel user) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('Supabase não configurado.');
    }

    final AuthResponse response;
    try {
      if (client.auth.currentSession != null) {
        await client.auth.signOut();
      }

      response = await client.auth.signUp(
        email: user.email,
        password: user.password,
        data: {'name': user.name},
      );
    } on AuthException catch (error) {
      if (_isAlreadyRegisteredError(error.message, code: error.code)) {
        try {
          final existingUser = await _doSignIn(
            client,
            email: user.email,
            password: user.password,
          );
          if (existingUser.supabaseId != null) {
            try {
              await upsertProfile(
                supabaseId: existingUser.supabaseId!,
                name: user.name,
                email: user.email,
              );
            } catch (_) {}
          }
          return SupabaseSignUpResult(
            user: existingUser.copyWith(name: user.name, password: ''),
            requiresEmailConfirmation: false,
          );
        } on AuthException {
          throw const AuthException(
            'Este e-mail já está cadastrado, mas a senha informada não confere.',
          );
        }
      }
      rethrow;
    }
    final remoteUser = response.user;
    if (remoteUser == null) {
      throw const AuthException('Não foi possível criar o usuário.');
    }

    var createdUser = user.copyWith(
      password: '',
      supabaseId: remoteUser.id,
    );
    var session = response.session;

    if (session == null) {
      try {
        final loginResponse = await client.auth.signInWithPassword(
          email: user.email,
          password: user.password,
        );
        session = loginResponse.session;
        if (loginResponse.user != null) {
          createdUser = user.copyWith(
            password: '',
            supabaseId: loginResponse.user!.id,
          );
        }
      } catch (_) {}
    }

    final requiresEmailConfirmation = session == null;

    if (!requiresEmailConfirmation && createdUser.supabaseId != null) {
      try {
        await upsertProfile(
          supabaseId: createdUser.supabaseId!,
          name: user.name,
          email: user.email,
        );
      } catch (_) {}
    }

    return SupabaseSignUpResult(
      user: createdUser,
      requiresEmailConfirmation: requiresEmailConfirmation,
    );
  }

  Future<UserModel?> currentAuthenticatedUser() async {
    final client = _client;
    final authUser = client?.auth.currentUser;
    if (client == null || authUser == null || authUser.email == null) {
      return null;
    }

    final profile = await _loadProfileSafely(authUser.id);
    final email = authUser.email!;
    final name = profile?['name'] as String? ??
        authUser.userMetadata?['name'] as String? ??
        email.split('@').first;

    return UserModel(
      name: name,
      email: email,
      password: '',
      supabaseId: authUser.id,
    );
  }

  Future<Map<String, dynamic>?> _loadProfile(String supabaseId) async {
    final client = _client;
    if (client == null) return null;

    final rows =
        await client.from('profiles').select().eq('id', supabaseId).limit(1);

    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<Map<String, dynamic>?> _loadProfileSafely(String supabaseId) async {
    try {
      return await _loadProfile(supabaseId);
    } catch (_) {
      return null;
    }
  }

  bool _isAlreadyRegisteredError(String message, {String? code}) {
    final normalizedCode = code?.toLowerCase() ?? '';
    final normalized = message.toLowerCase();
    return normalizedCode == 'user_already_exists' ||
        normalizedCode == 'email_exists' ||
        normalized.contains('already registered') ||
        normalized.contains('already been registered') ||
        normalized.contains('user already registered') ||
        normalized.contains('user already exists') ||
        normalized.contains('email already exists');
  }

  Future<void> upsertProfile({
    required String supabaseId,
    required String name,
    required String email,
  }) async {
    final client = _client;
    if (client == null) return;

    await client.from('profiles').upsert({
      'id': supabaseId,
      'name': name,
      'email': email,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateProfileName({
    required String supabaseId,
    required String name,
    required String email,
  }) async {
    final client = _client;
    if (client == null) return;

    try {
      await client.auth.updateUser(
        UserAttributes(data: {'name': name}),
      );
    } catch (_) {}

    await upsertProfile(
      supabaseId: supabaseId,
      name: name,
      email: email,
    );
  }

  Future<List<TransactionModel>> fetchTransactions({
    required int localUserId,
  }) async {
    final client = _client;
    final remoteUserId = client?.auth.currentUser?.id;
    if (client == null || remoteUserId == null) return [];

    final rows = await client
        .from('transactions')
        .select()
        .eq('user_id', remoteUserId)
        .order('date', ascending: false);

    return rows.map<TransactionModel>((row) {
      return TransactionModel(
        id: row['local_id'] as int?,
        userId: localUserId,
        description: row['title'] as String,
        amount: (row['amount'] as num).toDouble(),
        type: TransactionType.values.firstWhere(
          (value) => value.name == row['type'],
          orElse: () => TransactionType.despesa,
        ),
        category: row['category'] as String,
        date: DateTime.parse(row['date'] as String),
        createdAt: DateTime.parse(row['created_at'] as String),
      );
    }).toList();
  }

  Future<void> upsertTransaction(TransactionModel transaction) async {
    final client = _client;
    final remoteUserId = client?.auth.currentUser?.id;
    if (client == null || remoteUserId == null || transaction.id == null) {
      return;
    }

    await client.from('transactions').upsert(
      {
        'user_id': remoteUserId,
        'local_id': transaction.id,
        'title': transaction.description,
        'amount': transaction.amount,
        'type': transaction.type.name,
        'category': transaction.category,
        'date': transaction.date.toIso8601String(),
        'created_at': transaction.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,local_id',
    );
  }

  Future<void> deleteTransaction(int localId) async {
    final client = _client;
    final remoteUserId = client?.auth.currentUser?.id;
    if (client == null || remoteUserId == null) return;

    await client
        .from('transactions')
        .delete()
        .eq('user_id', remoteUserId)
        .eq('local_id', localId);
  }

  Future<void> signOut() async {
    final client = _client;
    if (client == null) return;
    await client.auth.signOut();
  }
}
