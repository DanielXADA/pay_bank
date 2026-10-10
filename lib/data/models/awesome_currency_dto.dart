import '../../core/value_objects/money.dart';
import '../../domain/entities/currency_quote.dart';

/// DTO da Camada Anti-Corrupção (ACL) para a AwesomeAPI de cotações cambiais.
///
/// Trata os tipos retornados em String (ex: "bid": "5.4312") e converte
/// para Money (centavos) e tipos de domínio seguros.
class AwesomeCurrencyDto {
  final String code;
  final String codein;
  final String name;
  final String high;
  final String low;
  final String varBid;
  final String pctChange;
  final String bid;
  final String ask;
  final String timestamp;
  final String createDate;

  const AwesomeCurrencyDto({
    required this.code,
    required this.codein,
    required this.name,
    required this.high,
    required this.low,
    required this.varBid,
    required this.pctChange,
    required this.bid,
    required this.ask,
    required this.timestamp,
    required this.createDate,
  });

  factory AwesomeCurrencyDto.fromJson(Map<String, dynamic> json) {
    return AwesomeCurrencyDto(
      code: (json['code'] as String?) ?? '',
      codein: (json['codein'] as String?) ?? 'BRL',
      name: (json['name'] as String?) ?? '',
      high: (json['high'] as String?) ?? '0.0',
      low: (json['low'] as String?) ?? '0.0',
      varBid: (json['varBid'] as String?) ?? '0.0',
      pctChange: (json['pctChange'] as String?) ?? '0.0',
      bid: (json['bid'] as String?) ?? '0.0',
      ask: (json['ask'] as String?) ?? '0.0',
      timestamp: (json['timestamp'] as String?) ?? '',
      createDate: (json['create_date'] as String?) ?? '',
    );
  }

  /// Converte para a Entidade de Domínio CurrencyQuote com Value Object Money.
  CurrencyQuote toDomain() {
    final bidVal = double.tryParse(bid) ?? 0.0;
    final askVal = double.tryParse(ask) ?? 0.0;
    final highVal = double.tryParse(high) ?? 0.0;
    final lowVal = double.tryParse(low) ?? 0.0;
    final variationVal = double.tryParse(pctChange) ?? 0.0;

    DateTime date;
    if (timestamp.isNotEmpty) {
      final seconds = int.tryParse(timestamp);
      date = seconds != null
          ? DateTime.fromMillisecondsSinceEpoch(seconds * 1000)
          : DateTime.now();
    } else {
      date = DateTime.tryParse(createDate) ?? DateTime.now();
    }

    return CurrencyQuote(
      code: code,
      codeIn: codein,
      name: name,
      bid: Money.fromDouble(bidVal),
      ask: Money.fromDouble(askVal),
      high: Money.fromDouble(highVal),
      low: Money.fromDouble(lowVal),
      pctChange: variationVal,
      updatedAt: date,
    );
  }
}
