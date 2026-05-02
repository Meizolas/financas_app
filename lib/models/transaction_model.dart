enum TransactionType { receita, despesa }

class TransactionModel {
  final String id;
  final String description;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String category;

  TransactionModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
    required this.category,
  });
}
