import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class FinanceViewModel extends ChangeNotifier {
  final List<TransactionModel> _transactions = [];

  List<TransactionModel> get transactions => List.unmodifiable(_transactions);

  // Transações ordenadas por data (mais recentes primeiro)
  List<TransactionModel> get recentTransactions {
    final sorted = List<TransactionModel>.from(_transactions);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  // Cálculos financeiros
  double get totalReceitas => _transactions
      .where((t) => t.type == TransactionType.receita)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalDespesas => _transactions
      .where((t) => t.type == TransactionType.despesa)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get saldo => totalReceitas - totalDespesas;

  // Gastos por categoria
  Map<String, double> get gastosPorCategoria {
    final map = <String, double>{};
    for (final t in _transactions) {
      if (t.type == TransactionType.despesa) {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    return map;
  }

  // Receitas por categoria
  Map<String, double> get receitasPorCategoria {
    final map = <String, double>{};
    for (final t in _transactions) {
      if (t.type == TransactionType.receita) {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    return map;
  }

  // Adicionar transação
  void addTransaction({
    required String description,
    required double amount,
    required TransactionType type,
    required String category,
  }) {
    final transaction = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: description,
      amount: amount,
      type: type,
      date: DateTime.now(),
      category: category,
    );
    _transactions.add(transaction);
    notifyListeners();
  }

  // Remover transação
  void removeTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // Dados de exemplo para demonstração
  void loadSampleData() {
    if (_transactions.isNotEmpty) return;

    final now = DateTime.now();
    final samples = [
      TransactionModel(
        id: '1',
        description: 'Salário',
        amount: 5000.00,
        type: TransactionType.receita,
        date: now.subtract(const Duration(days: 1)),
        category: 'Salário',
      ),
      TransactionModel(
        id: '2',
        description: 'Freelance website',
        amount: 1200.00,
        type: TransactionType.receita,
        date: now.subtract(const Duration(days: 3)),
        category: 'Freelance',
      ),
      TransactionModel(
        id: '3',
        description: 'Aluguel',
        amount: 1500.00,
        type: TransactionType.despesa,
        date: now.subtract(const Duration(days: 2)),
        category: 'Moradia',
      ),
      TransactionModel(
        id: '4',
        description: 'Supermercado',
        amount: 450.00,
        type: TransactionType.despesa,
        date: now.subtract(const Duration(days: 1)),
        category: 'Alimentação',
      ),
      TransactionModel(
        id: '5',
        description: 'Conta de luz',
        amount: 180.00,
        type: TransactionType.despesa,
        date: now.subtract(const Duration(days: 4)),
        category: 'Contas',
      ),
      TransactionModel(
        id: '6',
        description: 'Uber',
        amount: 35.00,
        type: TransactionType.despesa,
        date: now,
        category: 'Transporte',
      ),
      TransactionModel(
        id: '7',
        description: 'Netflix',
        amount: 55.90,
        type: TransactionType.despesa,
        date: now.subtract(const Duration(days: 5)),
        category: 'Lazer',
      ),
      TransactionModel(
        id: '8',
        description: 'Venda online',
        amount: 300.00,
        type: TransactionType.receita,
        date: now.subtract(const Duration(days: 6)),
        category: 'Vendas',
      ),
    ];

    _transactions.addAll(samples);
    notifyListeners();
  }
}
