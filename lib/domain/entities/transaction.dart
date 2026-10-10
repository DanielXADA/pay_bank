import '../../core/errors/exceptions.dart';
import '../../core/value_objects/money.dart';
import 'entry.dart';

enum TransactionType {
  pixTransfer,
  deposit,
  reversal;

  String get label {
    switch (this) {
      case TransactionType.pixTransfer:
        return 'Transferência PIX';
      case TransactionType.deposit:
        return 'Depósito em Conta';
      case TransactionType.reversal:
        return 'Estorno de Transação';
    }
  }
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  rolledBack;
}

/// Representa a Transação de Negócio (Aggregate Root no Core Banking).
///
/// Uma transação financeira atômica encapsula os lançamentos do Ledger (Entries)
/// e assegura a propriedade Zero-Sum (a soma dos débitos deve anular a soma dos créditos).
class Transaction {
  final String id;
  final String idempotencyKey;
  final TransactionType type;
  final TransactionStatus status;
  final Money amount;
  final String description;
  final int? senderAccountId;
  final int? receiverAccountId;
  final String? senderName;
  final String? receiverName;
  final String? receiverCpf;
  final List<Entry> entries;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.idempotencyKey,
    required this.type,
    required this.status,
    required this.amount,
    required this.description,
    this.senderAccountId,
    this.receiverAccountId,
    this.senderName,
    this.receiverName,
    this.receiverCpf,
    this.entries = const [],
    required this.createdAt,
  });

  /// Invariante Contábil Fundamental: Soma de todos os lançamentos deve ser exatamente ZERO.
  bool get isZeroSum {
    if (entries.isEmpty) return false;
    final total = entries.fold<Money>(
      const Money.zero(),
      (sum, entry) => sum + entry.signedAmount,
    );
    return total.isZero;
  }

  /// Valida se a transação obedece a todas as invariantes contábeis antes do commit.
  void validateInvariants() {
    if (amount.isNegative || amount.isZero) {
      throw ArgumentError('O valor da transação deve ser estritamente positivo.');
    }
    if (entries.isNotEmpty && !isZeroSum) {
      throw const LedgerUnbalancedException();
    }
  }

  Transaction copyWith({
    String? id,
    String? idempotencyKey,
    TransactionType? type,
    TransactionStatus? status,
    Money? amount,
    String? description,
    int? senderAccountId,
    int? receiverAccountId,
    String? senderName,
    String? receiverName,
    String? receiverCpf,
    List<Entry>? entries,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      type: type ?? this.type,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      senderAccountId: senderAccountId ?? this.senderAccountId,
      receiverAccountId: receiverAccountId ?? this.receiverAccountId,
      senderName: senderName ?? this.senderName,
      receiverName: receiverName ?? this.receiverName,
      receiverCpf: receiverCpf ?? this.receiverCpf,
      entries: entries ?? this.entries,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
