import '../../core/value_objects/money.dart';
import '../../domain/entities/transaction.dart';
import 'entry_model.dart';

class TransactionModel {
  final String id;
  final String idempotencyKey;
  final String type; // 'PIX_TRANSFER' | 'DEPOSIT' | 'REVERSAL'
  final String status; // 'PENDING' | 'COMPLETED' | 'FAILED' | 'ROLLED_BACK'
  final int amountCents;
  final String description;
  final int? senderAccountId;
  final int? receiverAccountId;
  final String? senderName;
  final String? receiverName;
  final String? receiverCpf;
  final String createdAt;
  final List<EntryModel> entries;

  const TransactionModel({
    required this.id,
    required this.idempotencyKey,
    required this.type,
    required this.status,
    required this.amountCents,
    required this.description,
    this.senderAccountId,
    this.receiverAccountId,
    this.senderName,
    this.receiverName,
    this.receiverCpf,
    required this.createdAt,
    this.entries = const [],
  });

  factory TransactionModel.fromDomain(Transaction transaction) {
    return TransactionModel(
      id: transaction.id,
      idempotencyKey: transaction.idempotencyKey,
      type: _mapTypeToString(transaction.type),
      status: _mapStatusToString(transaction.status),
      amountCents: transaction.amount.cents,
      description: transaction.description,
      senderAccountId: transaction.senderAccountId,
      receiverAccountId: transaction.receiverAccountId,
      senderName: transaction.senderName,
      receiverName: transaction.receiverName,
      receiverCpf: transaction.receiverCpf,
      createdAt: transaction.createdAt.toIso8601String(),
      entries: transaction.entries.map((e) => EntryModel.fromDomain(e)).toList(),
    );
  }

  factory TransactionModel.fromMap(
    Map<String, dynamic> map, [
    List<EntryModel> entries = const [],
  ]) {
    return TransactionModel(
      id: map['id'] as String,
      idempotencyKey: map['idempotency_key'] as String,
      type: map['type'] as String,
      status: map['status'] as String,
      amountCents: map['amount_cents'] as int,
      description: map['description'] as String,
      senderAccountId: map['sender_account_id'] as int?,
      receiverAccountId: map['receiver_account_id'] as int?,
      senderName: map['sender_name'] as String?,
      receiverName: map['receiver_name'] as String?,
      receiverCpf: map['receiver_cpf'] as String?,
      createdAt: map['created_at'] as String,
      entries: entries,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idempotency_key': idempotencyKey,
      'type': type,
      'status': status,
      'amount_cents': amountCents,
      'description': description,
      'sender_account_id': senderAccountId,
      'receiver_account_id': receiverAccountId,
      'sender_name': senderName,
      'receiver_name': receiverName,
      'receiver_cpf': receiverCpf,
      'created_at': createdAt,
    };
  }

  Transaction toDomain() {
    return Transaction(
      id: id,
      idempotencyKey: idempotencyKey,
      type: _mapStringToType(type),
      status: _mapStringToStatus(status),
      amount: Money.fromCents(amountCents),
      description: description,
      senderAccountId: senderAccountId,
      receiverAccountId: receiverAccountId,
      senderName: senderName,
      receiverName: receiverName,
      receiverCpf: receiverCpf,
      entries: entries.map((e) => e.toDomain()).toList(),
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
    );
  }

  static String _mapTypeToString(TransactionType type) {
    switch (type) {
      case TransactionType.pixTransfer:
        return 'PIX_TRANSFER';
      case TransactionType.deposit:
        return 'DEPOSIT';
      case TransactionType.reversal:
        return 'REVERSAL';
    }
  }

  static TransactionType _mapStringToType(String type) {
    switch (type) {
      case 'PIX_TRANSFER':
        return TransactionType.pixTransfer;
      case 'DEPOSIT':
        return TransactionType.deposit;
      case 'REVERSAL':
        return TransactionType.reversal;
      default:
        return TransactionType.pixTransfer;
    }
  }

  static String _mapStatusToString(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return 'PENDING';
      case TransactionStatus.completed:
        return 'COMPLETED';
      case TransactionStatus.failed:
        return 'FAILED';
      case TransactionStatus.rolledBack:
        return 'ROLLED_BACK';
    }
  }

  static TransactionStatus _mapStringToStatus(String status) {
    switch (status) {
      case 'PENDING':
        return TransactionStatus.pending;
      case 'COMPLETED':
        return TransactionStatus.completed;
      case 'FAILED':
        return TransactionStatus.failed;
      case 'ROLLED_BACK':
        return TransactionStatus.rolledBack;
      default:
        return TransactionStatus.completed;
    }
  }
}
