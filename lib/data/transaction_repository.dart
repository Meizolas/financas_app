import 'package:sqflite/sqflite.dart';

import '../models/transaction_model.dart';
import 'app_database.dart';
import 'supabase_remote_repository.dart';

class TransactionRepository {
  TransactionRepository({SupabaseRemoteRepository? remote})
      : _remote = remote ?? SupabaseRemoteRepository();

  final SupabaseRemoteRepository _remote;

  Future<List<TransactionModel>> findByUser(int userId) async {
    try {
      final db = await AppDatabase.instance();
      final rows = await db.query(
        'transactions',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'date DESC, id DESC',
      );

      return rows.map(TransactionModel.fromMap).toList();
    } catch (error) {
      if (!AppDatabase.isRecoverableWebDatabaseError(error)) {
        rethrow;
      }

      return _remote.fetchTransactions(localUserId: userId);
    }
  }

  Future<List<TransactionModel>> fetchRemote(int userId) {
    return _remote.fetchTransactions(localUserId: userId);
  }

  Future<TransactionModel> create(TransactionModel transaction) async {
    try {
      final db = await AppDatabase.instance();
      final id = await db.insert(
        'transactions',
        transaction.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final created = transaction.copyWith(id: id);
      try {
        await _remote.upsertTransaction(created);
      } catch (_) {
        // Mantem o app funcional offline/local quando o Supabase indisponivel.
      }
      return created;
    } catch (error) {
      if (!AppDatabase.isRecoverableWebDatabaseError(error)) {
        rethrow;
      }

      final created = transaction.copyWith(id: _temporaryLocalId());
      await _remote.upsertTransaction(created);
      return created;
    }
  }

  Future<void> update(TransactionModel transaction) async {
    try {
      final db = await AppDatabase.instance();
      await db.update(
        'transactions',
        transaction.toMap()..remove('id'),
        where: 'id = ? AND user_id = ?',
        whereArgs: [transaction.id, transaction.userId],
      );
      await _remote.upsertTransaction(transaction);
    } catch (error) {
      if (!AppDatabase.isRecoverableWebDatabaseError(error)) {
        // Mantem a atualizacao local mesmo se a sincronizacao falhar.
        return;
      }

      await _remote.upsertTransaction(transaction);
    }
  }

  Future<void> delete({
    required int id,
    required int userId,
  }) async {
    try {
      final db = await AppDatabase.instance();
      await db.delete(
        'transactions',
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );
      await _remote.deleteTransaction(id);
    } catch (error) {
      if (!AppDatabase.isRecoverableWebDatabaseError(error)) {
        // Mantem a exclusao local mesmo se a sincronizacao falhar.
        return;
      }

      await _remote.deleteTransaction(id);
    }
  }

  int _temporaryLocalId() {
    return DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
  }
}
