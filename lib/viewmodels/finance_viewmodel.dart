import 'package:flutter/material.dart';

import '../data/transaction_repository.dart';
import '../models/transaction_model.dart';

class FinanceViewModel extends ChangeNotifier {
  FinanceViewModel({TransactionRepository? repository})
      : _repository = repository ?? TransactionRepository();

  final TransactionRepository _repository;
  final List<TransactionModel> _transactions = [];

  int? _currentUserId;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);

  List<TransactionModel> get recentTransactions {
    final sorted = List<TransactionModel>.from(_transactions);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  double get totalReceitas => _transactions
      .where((transaction) => transaction.type == TransactionType.receita)
      .fold(0.0, (sum, transaction) => sum + transaction.amount);

  double get totalDespesas => _transactions
      .where((transaction) => transaction.type == TransactionType.despesa)
      .fold(0.0, (sum, transaction) => sum + transaction.amount);

  double get saldo => totalReceitas - totalDespesas;

  double get investimentos => 0.0;

  List<Map<String, dynamic>> get lastSixMonthsData {
    final now = DateTime.now();
    const labels = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
    ];
    return List.generate(6, (i) {
      final m = DateTime(now.year, now.month - (5 - i));
      final monthTx = _transactions
          .where((t) => t.date.year == m.year && t.date.month == m.month)
          .toList();
      final rec = monthTx
          .where((t) => t.type == TransactionType.receita)
          .fold(0.0, (s, t) => s + t.amount);
      final desp = monthTx
          .where((t) => t.type == TransactionType.despesa)
          .fold(0.0, (s, t) => s + t.amount);
      return {'label': labels[m.month - 1], 'net': rec - desp};
    });
  }

  double get thisMonthChangePercent {
    final now = DateTime.now();
    double netForMonth(int y, int m) => _transactions
        .where((t) => t.date.year == y && t.date.month == m)
        .fold(0.0, (s, t) => t.type == TransactionType.receita
            ? s + t.amount
            : s - t.amount);
    final cur = netForMonth(now.year, now.month);
    final prev = DateTime(now.year, now.month - 1);
    final last = netForMonth(prev.year, prev.month);
    if (last == 0) return 0;
    return ((cur - last) / last.abs()) * 100;
  }

  Map<String, double> get gastosPorCategoria {
    final map = <String, double>{};
    for (final transaction in _transactions) {
      if (transaction.type == TransactionType.despesa) {
        map[transaction.category] =
            (map[transaction.category] ?? 0) + transaction.amount;
      }
    }
    return map;
  }

  Map<String, double> get receitasPorCategoria {
    final map = <String, double>{};
    for (final transaction in _transactions) {
      if (transaction.type == TransactionType.receita) {
        map[transaction.category] =
            (map[transaction.category] ?? 0) + transaction.amount;
      }
    }
    return map;
  }

  Future<void> loadTransactions(int userId) async {
    if (_currentUserId == userId && _transactions.isNotEmpty) return;

    _currentUserId = userId;
    _setLoading(true);
    _errorMessage = null;

    try {
      final localTransactions = await _repository.findByUser(userId);
      _transactions
        ..clear()
        ..addAll(localTransactions);

      try {
        final remoteTransactions = await _repository.fetchRemote(userId);
        for (final remote in remoteTransactions) {
          final exists = _transactions.any((item) => item.id == remote.id);
          if (!exists) _transactions.add(remote);
        }
      } catch (_) {
        // O cache SQLite mantem o app funcional quando offline ou sem schema.
      }
    } catch (_) {
      _errorMessage = 'Não foi possível carregar suas transações.';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addTransaction({
    required String description,
    required double amount,
    required TransactionType type,
    required String category,
    required DateTime date,
    int? userId,
  }) async {
    final uid = _currentUserId ?? userId;
    if (uid == null) {
      _errorMessage = 'Usuário não autenticado.';
      notifyListeners();
      return false;
    }

    if (_currentUserId == null && userId != null) {
      _currentUserId = userId;
    }

    _errorMessage = null;
    try {
      final created = await _repository.create(
        TransactionModel(
          userId: uid,
          description: description,
          amount: amount,
          type: type,
          category: category,
          date: date,
        ),
      );

      _transactions.add(created);
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Não foi possível salvar a transação.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTransaction(TransactionModel transaction) async {
    if (transaction.id == null) return false;

    _errorMessage = null;
    try {
      await _repository.update(transaction);
      final index =
          _transactions.indexWhere((item) => item.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
      }
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Não foi possível atualizar a transação.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeTransaction(int id) async {
    final userId = _currentUserId;
    if (userId == null) return false;

    _errorMessage = null;
    try {
      await _repository.delete(id: id, userId: userId);
      _transactions.removeWhere((transaction) => transaction.id == id);
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Não foi possível excluir a transação.';
      notifyListeners();
      return false;
    }
  }

  void clear() {
    _currentUserId = null;
    _transactions.clear();
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
