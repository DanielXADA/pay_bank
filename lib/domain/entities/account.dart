import '../../core/value_objects/money.dart';
import 'entry.dart';

enum AccountType {
  checking, // Conta corrente do cliente
  systemVault, // Conta cofre/caixa do banco (para depósitos em dinheiro)
  systemClearing; // Conta de compensação externa (para PIX externo/liquidação)

  bool get isCustomer => this == AccountType.checking;
  bool get isSystem => this != AccountType.checking;
}

/// Representa a Conta Bancária no Core Banking.
///
/// O saldo de uma conta bancária NÃO é uma propriedade gravada diretamente,
/// mas sim um estado materializado derivado do somatório de seus lançamentos contábeis (Entries).
class Account {
  final int id;
  final int userId;
  final String accountNumber;
  final String agency;
  final AccountType type;
  final Money balance;
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.userId,
    required this.accountNumber,
    required this.agency,
    this.type = AccountType.checking,
    required this.balance,
    required this.createdAt,
  });

  /// Reconstrói a conta calculando o saldo dinamicamente via fold dos lançamentos contábeis.
  factory Account.fromLedger({
    required int id,
    required int userId,
    required String accountNumber,
    required String agency,
    AccountType type = AccountType.checking,
    required List<Entry> entries,
    required DateTime createdAt,
  }) {
    final calculatedBalance = entries.fold<Money>(
      const Money.zero(),
      (accumulated, entry) => accumulated + entry.signedAmount,
    );

    return Account(
      id: id,
      userId: userId,
      accountNumber: accountNumber,
      agency: agency,
      type: type,
      balance: calculatedBalance,
      createdAt: createdAt,
    );
  }

  /// Verifica se a conta possui fundos suficientes para um débito sem cheque especial.
  bool hasSufficientFunds(Money amount) {
    if (type.isSystem) return true; // Contas cofre de sistema podem manter posições de compensação
    return balance >= amount;
  }

  Account copyWith({
    int? id,
    int? userId,
    String? accountNumber,
    String? agency,
    AccountType? type,
    Money? balance,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountNumber: accountNumber ?? this.accountNumber,
      agency: agency ?? this.agency,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
