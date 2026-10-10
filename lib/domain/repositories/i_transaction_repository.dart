import '../../core/value_objects/money.dart';
import '../entities/transaction.dart';

/// Contrato para operações transacionais financeiras no Core Banking.
///
/// Todas as operações de mutação contábil exigem uma chave de idempotência
/// e devem ser executadas com garantia ACID (atomicidade e isolamento).
abstract class ITransactionRepository {
  /// Executa uma transferência PIX entre contas bancárias de forma atômica e idempotente.
  Future<Transaction> executePixTransfer({
    required String idempotencyKey,
    required int senderAccountId,
    required int receiverAccountId,
    required Money amount,
    String? description,
  });

  /// Executa um depósito simulado de fundos na conta do usuário contra o caixa do sistema.
  Future<Transaction> executeDeposit({
    required String idempotencyKey,
    required int accountId,
    required Money amount,
    String? description,
  });

  /// Recupera o histórico de transações que impactaram a conta do usuário.
  Future<List<Transaction>> getTransactionsForAccount(int accountId);

  /// Consulta transação existente por chave de idempotência (prevenção de duplicidade).
  Future<Transaction?> getTransactionByIdempotencyKey(String idempotencyKey);
}
