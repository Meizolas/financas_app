class MarketIndicatorModel {
  const MarketIndicatorModel({
    required this.name,
    required this.value,
  });

  final String name;
  final double value;

  factory MarketIndicatorModel.fromMap(Map<String, dynamic> map) {
    return MarketIndicatorModel(
      name: map['nome'] as String,
      value: (map['valor'] as num).toDouble(),
    );
  }
}
