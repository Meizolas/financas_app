enum TransactionType { receita, despesa }

class TransactionModel {
  final int? id;
  final int userId;
  final String description;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String category;
  final DateTime createdAt;

  TransactionModel({
    this.id,
    required this.userId,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
    required this.category,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get title => description;

  TransactionModel copyWith({
    int? id,
    int? userId,
    String? description,
    double? amount,
    TransactionType? type,
    DateTime? date,
    String? category,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': description,
      'amount': amount,
      'type': type.name,
      'category': category,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, Object?> map) {
    return TransactionModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      description: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => TransactionType.despesa,
      ),
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
