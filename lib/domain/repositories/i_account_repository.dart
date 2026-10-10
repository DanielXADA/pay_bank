import '../../core/value_objects/money.dart';
import '../entities/account.dart';
import '../entities/entry.dart';

/// Contrato para gestão de contas bancárias e extração de extratos do Ledger.
abstract class IAccountRepository {
  /// Obtém a conta associada a um usuário específico.
  Future<Account> getAccountByUserId(int userId);

  /// Obtém a conta pelo seu identificador primário.
  Future<Account> getAccountById(int accountId);

  /// Deriva o saldo atual da conta através do somatório de lançamentos (Ledger fold).
  Future<Money> getBalance(int accountId);

  /// Obtém o extrato detalhado de lançamentos contábeis (Entries) da conta.
  Future<List<Entry>> getEntriesForAccount(int accountId);
}
