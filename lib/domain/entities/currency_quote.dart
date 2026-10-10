import '../../core/value_objects/money.dart';

/// Entidade de cotação de moedas em tempo real desacoplada da AwesomeAPI.
class CurrencyQuote {
  final String code; // ex: USD
  final String codeIn; // ex: BRL
  final String name; // ex: Dólar Americano/Real Brasileiro
  final Money bid; // Preço de Compra
  final Money ask; // Preço de Venda
  final Money high; // Máxima
  final Money low; // Mínima
  final double pctChange; // Variação percentual
  final DateTime updatedAt;

  const CurrencyQuote({
    required this.code,
    required this.codeIn,
    required this.name,
    required this.bid,
    required this.ask,
    required this.high,
    required this.low,
    required this.pctChange,
    required this.updatedAt,
  });

  bool get isPositiveVariation => pctChange >= 0;

  String get pair => '$code/$codeIn';
}
