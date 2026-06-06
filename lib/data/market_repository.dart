import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/market_indicator_model.dart';

class MarketRepository {
  static const _endpoint = 'https://brasilapi.com.br/api/taxas/v1';

  Future<List<MarketIndicatorModel>> fetchIndicators() async {
    final response = await http
        .get(Uri.parse(_endpoint))
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception('Falha ao carregar indicadores financeiros.');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return decoded
        .map((item) => MarketIndicatorModel.fromMap(item))
        .take(4)
        .toList();
  }
}
