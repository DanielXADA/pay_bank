import '../../core/value_objects/money.dart';
import '../../domain/entities/entry.dart';

class EntryModel {
  final int? id;
  final String transactionId;
  final int accountId;
  final String type; // 'DEBIT' | 'CREDIT'
  final int amountCents;
  final int signedAmountCents;
  final String? description;
  final String createdAt;

  const EntryModel({
    this.id,
    required this.transactionId,
    required this.accountId,
    required this.type,
    required this.amountCents,
    required this.signedAmountCents,
    this.description,
    required this.createdAt,
  });

  factory EntryModel.fromDomain(Entry entry) {
    return EntryModel(
      id: entry.id,
      transactionId: entry.transactionId,
      accountId: entry.accountId,
      type: entry.type == EntryType.debit ? 'DEBIT' : 'CREDIT',
      amountCents: entry.amount.cents,
      signedAmountCents: entry.signedAmount.cents,
      description: entry.description,
      createdAt: entry.createdAt.toIso8601String(),
    );
  }

  factory EntryModel.fromMap(Map<String, dynamic> map) {
    return EntryModel(
      id: map['id'] as int?,
      transactionId: map['transaction_id'] as String,
      accountId: map['account_id'] as int,
      type: map['type'] as String,
      amountCents: map['amount_cents'] as int,
      signedAmountCents: map['signed_amount_cents'] as int,
      description: map['description'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'transaction_id': transactionId,
      'account_id': accountId,
      'type': type,
      'amount_cents': amountCents,
      'signed_amount_cents': signedAmountCents,
      'description': description,
      'created_at': createdAt,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  Entry toDomain() {
    return Entry(
      id: id,
      transactionId: transactionId,
      accountId: accountId,
      type: type == 'DEBIT' ? EntryType.debit : EntryType.credit,
      amount: Money.fromCents(amountCents),
      description: description,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
    );
  }
}
