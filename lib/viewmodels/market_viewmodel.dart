import 'package:flutter/material.dart';

import '../data/market_repository.dart';
import '../models/market_indicator_model.dart';

class MarketViewModel extends ChangeNotifier {
  MarketViewModel({MarketRepository? repository})
      : _repository = repository ?? MarketRepository();

  final MarketRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  List<MarketIndicatorModel> _indicators = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<MarketIndicatorModel> get indicators => List.unmodifiable(_indicators);

  Future<void> reload() async {
    _indicators = [];
    _errorMessage = null;
    await load();
  }

  Future<void> load() async {
    if (_isLoading || _indicators.isNotEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _indicators = await _repository.fetchIndicators();
    } catch (_) {
      _errorMessage = 'Não foi possível carregar indicadores externos.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
