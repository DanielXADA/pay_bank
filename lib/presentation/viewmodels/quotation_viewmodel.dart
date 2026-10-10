import 'package:flutter/foundation.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/currency_quote.dart';
import '../../domain/repositories/i_currency_repository.dart';
import '../../data/repositories/currency_repository_impl.dart';

/// ViewModel reativa (MVVM) para cotações cambiais e conversão de moedas.
///
/// Consome o [ICurrencyRepository] isolando a Camada Anti-Corrupção (ACL) da AwesomeAPI.
class QuotationViewModel extends ChangeNotifier {
  final ICurrencyRepository _currencyRepository;

  bool _isLoading = true;
  String? _errorMessage;
  List<CurrencyQuote> _quotes = [];
  DateTime? _lastUpdated;
  String _activeCurrencyCode = 'USD';
  double _conversionResult = 0.0;

  QuotationViewModel({ICurrencyRepository? currencyRepository})
      : _currencyRepository = currencyRepository ?? CurrencyRepositoryImpl();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<CurrencyQuote> get quotes => _quotes;
  DateTime? get lastUpdated => _lastUpdated;
  String get activeCurrencyCode => _activeCurrencyCode;
  double get conversionResult => _conversionResult;

  CurrencyQuote? get activeQuote {
    final match = _quotes.where((q) => q.code == _activeCurrencyCode);
    return match.isNotEmpty ? match.first : null;
  }

  void setActiveCurrency(String code, [double? currentBrlValue]) {
    _activeCurrencyCode = code;
    if (currentBrlValue != null) {
      calculateConversion(currentBrlValue);
    } else {
      notifyListeners();
    }
  }

  /// Busca as cotações em tempo real através da ACL do repositório.
  Future<void> loadQuotes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _currencyRepository.getRealTimeQuotes();
      _quotes = result;
      _lastUpdated = DateTime.now();
      _isLoading = false;
      notifyListeners();
    } on Failure catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao consultar cotações cambiais. Verifique sua conexão.';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Converte valor em Reais (BRL) para a moeda estrangeira ativa.
  void calculateConversion(double valueInBrl) {
    final quote = activeQuote;
    if (quote != null && quote.bid.toDouble() > 0) {
      _conversionResult = valueInBrl / quote.bid.toDouble();
    } else {
      _conversionResult = 0.0;
    }
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
