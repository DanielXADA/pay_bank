/// Value Object imutável para representar valores monetários com precisão exata.
///
/// Utiliza inteiros (centavos) para eliminar qualquer risco de erro de ponto
/// flutuante inerente ao padrão IEEE 754 em cálculos financeiros.
class Money implements Comparable<Money> {
  final int cents;
  final String currency;

  const Money.fromCents(this.cents, {this.currency = 'BRL'});

  /// Cria Money a partir de um valor double arredondando para os centavos mais próximos.
  factory Money.fromDouble(double value, {String currency = 'BRL'}) {
    final cents = (value * 100).round();
    return Money.fromCents(cents, currency: currency);
  }

  /// Cria Money zerado.
  const Money.zero({String currency = 'BRL'}) : this.fromCents(0, currency: currency);

  double toDouble() => cents / 100.0;

  bool get isZero => cents == 0;
  bool get isPositive => cents > 0;
  bool get isNegative => cents < 0;

  Money abs() => Money.fromCents(cents.abs(), currency: currency);

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money.fromCents(cents + other.cents, currency: currency);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money.fromCents(cents - other.cents, currency: currency);
  }

  Money operator *(num factor) {
    return Money.fromCents((cents * factor).round(), currency: currency);
  }

  Money operator -() {
    return Money.fromCents(-cents, currency: currency);
  }

  bool operator <(Money other) {
    _assertSameCurrency(other);
    return cents < other.cents;
  }

  bool operator <=(Money other) {
    _assertSameCurrency(other);
    return cents <= other.cents;
  }

  bool operator >(Money other) {
    _assertSameCurrency(other);
    return cents > other.cents;
  }

  bool operator >=(Money other) {
    _assertSameCurrency(other);
    return cents >= other.cents;
  }

  @override
  int compareTo(Money other) {
    _assertSameCurrency(other);
    return cents.compareTo(other.cents);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money &&
          runtimeType == other.runtimeType &&
          cents == other.cents &&
          currency == other.currency;

  @override
  int get hashCode => cents.hashCode ^ currency.hashCode;

  /// Formata para o padrão brasileiro: R$ 1.250,50 ou -R$ 50,00
  String get formatted {
    final prefix = currency == 'BRL' ? 'R\$ ' : '$currency ';
    final sign = isNegative ? '-' : '';
    return '$sign$prefix$formattedWithoutSymbol';
  }

  /// Retorna apenas o valor formatado com separador de milhar e centavos: 1.250,50
  String get formattedWithoutSymbol {
    final absoluteCents = cents.abs();
    final wholePart = absoluteCents ~/ 100;
    final decimalPart = (absoluteCents % 100).toString().padLeft(2, '0');

    final wholeString = wholePart.toString();
    final buffer = StringBuffer();
    final length = wholeString.length;

    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(wholeString[i]);
    }

    return '$buffer,$decimalPart';
  }

  void _assertSameCurrency(Money other) {
    if (currency != other.currency) {
      throw ArgumentError(
        'Não é possível realizar operações entre moedas distintas: $currency e ${other.currency}',
      );
    }
  }

  @override
  String toString() => formatted;
}
