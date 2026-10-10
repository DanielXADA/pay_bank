import '../../core/value_objects/money.dart';

/// Natureza do lançamento contábil:
/// - [debit]: Saída de recursos da conta bancária.
/// - [credit]: Entrada de recursos na conta bancária.
enum EntryType {
  debit,
  credit;

  bool get isDebit => this == EntryType.debit;
  bool get isCredit => this == EntryType.credit;
}

/// Representa um lançamento contábil imutável no Ledger de Partidas Dobradas.
///
/// Princípio fundamental: Lançamentos nunca sofrem UPDATE ou DELETE.
/// Todo ajuste ou estorno é realizado por novos lançamentos compensatórios.
class Entry {
  final int? id;
  final String transactionId;
  final int accountId;
  final EntryType type;
  final Money amount;
  final String? description;
  final DateTime createdAt;

  const Entry({
    this.id,
    required this.transactionId,
    required this.accountId,
    required this.type,
    required this.amount,
    this.description,
    required this.createdAt,
  });

  /// Valor com sinal para cálculo de balanço e soma contábil zero-sum:
  /// - Débito reduz o ativo/saldo do cliente (-amount)
  /// - Crédito aumenta o ativo/saldo do cliente (+amount)
  Money get signedAmount => type == EntryType.debit ? -amount : amount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Entry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          transactionId == other.transactionId &&
          accountId == other.accountId &&
          type == other.type &&
          amount == other.amount &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      transactionId.hashCode ^
      accountId.hashCode ^
      type.hashCode ^
      amount.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'Entry(id: $id, txn: $transactionId, account: $accountId, type: ${type.name}, amount: $amount, date: $createdAt)';
  }
}
