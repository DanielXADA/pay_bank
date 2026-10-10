/// Exceções de infraestrutura e domínio para o ecossistema PayBank.
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => '$runtimeType: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Saldo insuficiente para realizar a transferência/saque.
class InsufficientFundsException extends AppException {
  const InsufficientFundsException([String message = 'Saldo insuficiente para realizar a operação.'])
      : super(message, code: 'INSUFFICIENT_FUNDS');
}

/// Violação de idempotência (chave repetida ou transação já processada).
class IdempotencyConflictException extends AppException {
  const IdempotencyConflictException([String message = 'Transação duplicada detectada (Idempotency Key já utilizada).'])
      : super(message, code: 'IDEMPOTENCY_CONFLICT');
}

/// Inconsistência contábil no Ledger (partidas não totalizam zero).
class LedgerUnbalancedException extends AppException {
  const LedgerUnbalancedException([String message = 'Erro de integridade contábil: o total de débitos difere do total de créditos (não é zero-sum).'])
      : super(message, code: 'LEDGER_UNBALANCED');
}

/// Conta bancária não encontrada.
class AccountNotFoundException extends AppException {
  const AccountNotFoundException([String message = 'Conta bancária de origem ou destino não encontrada.'])
      : super(message, code: 'ACCOUNT_NOT_FOUND');
}

/// Usuário não encontrado ou credenciais inválidas.
class AuthenticationException extends AppException {
  const AuthenticationException([String message = 'Falha de autenticação ou credenciais inválidas.'])
      : super(message, code: 'AUTH_ERROR');
}

/// Senha de transação (PIN) incorreta.
class InvalidTransactionPinException extends AppException {
  const InvalidTransactionPinException([String message = 'Senha de transação incorreta.'])
      : super(message, code: 'INVALID_PIN');
}

/// Chave PIX não encontrada no diretório local.
class PixKeyNotFoundException extends AppException {
  const PixKeyNotFoundException([String message = 'Chave PIX informada não foi localizada.'])
      : super(message, code: 'PIX_KEY_NOT_FOUND');
}

/// Falha de rede ou timeout ao acessar serviços externos (ViaCEP, AwesomeAPI).
class ExternalServiceException extends AppException {
  const ExternalServiceException(String message, {String? code})
      : super(message, code: code ?? 'EXTERNAL_SERVICE_ERROR');
}

/// Dispositivo sem conexão de rede (SocketException, timeout, offline).
class NetworkException extends AppException {
  const NetworkException([String message = 'Sem conexão com a internet.'])
      : super(message, code: 'NETWORK_ERROR');
}

/// Resposta de erro HTTP (ex: 500, 502, 404).
class ServerException extends AppException {
  const ServerException([String message = 'Erro de comunicação com o servidor remoto.'])
      : super(message, code: 'SERVER_ERROR');
}

/// Falha no banco de dados local SQLite.
class DatabaseOperationException extends AppException {
  const DatabaseOperationException(String message, {String? code})
      : super(message, code: code ?? 'DB_ERROR');
}
