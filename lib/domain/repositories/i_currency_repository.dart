import '../entities/currency_quote.dart';

/// Contrato para cotação cambial (Anti-Corruption Layer sobre AwesomeAPI).
abstract class ICurrencyRepository {
  /// Retorna as cotações em tempo real normalizadas para as entidades do domínio.
  Future<List<CurrencyQuote>> getRealTimeQuotes();
}
