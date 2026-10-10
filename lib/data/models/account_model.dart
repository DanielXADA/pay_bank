import '../../core/value_objects/money.dart';
import '../../domain/entities/account.dart';

class AccountModel {
  final int id;
  final int userId;
  final String accountNumber;
  final String agency;
  final String type; // 'CHECKING' | 'SYSTEM_VAULT' | 'SYSTEM_CLEARING'
  final String createdAt;
  final int balanceCents;

  const AccountModel({
    required this.id,
    required this.userId,
    required this.accountNumber,
    required this.agency,
    required this.type,
    required this.createdAt,
    this.balanceCents = 0,
  });

  factory AccountModel.fromDomain(Account account) {
    return AccountModel(
      id: account.id,
      userId: account.userId,
      accountNumber: account.accountNumber,
      agency: account.agency,
      type: _mapTypeToString(account.type),
      createdAt: account.createdAt.toIso8601String(),
      balanceCents: account.balance.cents,
    );
  }

  factory AccountModel.fromMap(Map<String, dynamic> map, [int balanceCents = 0]) {
    return AccountModel(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      accountNumber: map['account_number'] as String,
      agency: map['agency'] as String,
      type: (map['type'] as String?) ?? 'CHECKING',
      createdAt: map['created_at'] as String,
      balanceCents: balanceCents,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'account_number': accountNumber,
      'agency': agency,
      'type': type,
      'created_at': createdAt,
    };
  }

  Account toDomain() {
    return Account(
      id: id,
      userId: userId,
      accountNumber: accountNumber,
      agency: agency,
      type: _mapStringToType(type),
      balance: Money.fromCents(balanceCents),
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
    );
  }

  static String _mapTypeToString(AccountType type) {
    switch (type) {
      case AccountType.checking:
        return 'CHECKING';
      case AccountType.systemVault:
        return 'SYSTEM_VAULT';
      case AccountType.systemClearing:
        return 'SYSTEM_CLEARING';
    }
  }

  static AccountType _mapStringToType(String type) {
    switch (type) {
      case 'CHECKING':
        return AccountType.checking;
      case 'SYSTEM_VAULT':
        return AccountType.systemVault;
      case 'SYSTEM_CLEARING':
        return AccountType.systemClearing;
      default:
        return AccountType.checking;
    }
  }
}
