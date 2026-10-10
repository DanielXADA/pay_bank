import '../../core/value_objects/money.dart';
import '../entities/user.dart';

/// Contrato para gestão cadastral e diretório de chaves PIX.
abstract class IUserRepository {
  /// Cadastra um novo correntista, abrindo sua conta bancária e provisionando saldo inicial via Ledger.
  Future<User> registerUser({
    required User user,
    required String password,
    required String transactionPassword,
    Money? initialDeposit,
  });

  /// Busca correntista pelo ID.
  Future<User?> getUserById(int id);

  /// Busca correntista pelo nome de usuário.
  Future<User?> getUserByUsername(String username);

  /// Busca o correntista destinatário a partir do tipo e valor da chave PIX informada.
  Future<User?> getUserByPixKey({
    required String type,
    required String key,
  });

  /// Atualiza os dados cadastrais do correntista.
  Future<void> updateUser(User user);

  /// Habilita ou desabilita chaves PIX do correntista.
  Future<void> updatePixKeys({
    required int userId,
    required bool isCpfActive,
    required bool isEmailActive,
    required bool isPhoneActive,
  });
}
