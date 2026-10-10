import '../entities/user.dart';

/// Contrato para segurança, autenticação e biometria.
abstract class IAuthRepository {
  /// Autentica correntista por nome de usuário e senha principal.
  Future<User?> login({
    required String username,
    required String password,
  });

  /// Realiza autenticação biométrica (Face ID / Digital).
  Future<bool> authenticateWithBiometrics();

  /// Valida o PIN / senha transacional antes de autorizar movimentações de fundos.
  Future<bool> verifyTransactionPin({
    required int userId,
    required String pin,
  });

  /// Altera a senha de acesso ao aplicativo.
  Future<void> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  });

  /// Altera a senha transacional (PIN de 4 ou 6 dígitos).
  Future<void> changeTransactionPin({
    required int userId,
    required String currentPin,
    required String newPin,
  });

  /// Persiste a sessão do usuário logado.
  Future<void> saveSession(String username);

  /// Recupera o usuário da sessão ativa.
  Future<String?> getCurrentSessionUsername();

  /// Finaliza a sessão do usuário (Logout).
  Future<void> logout();
}
