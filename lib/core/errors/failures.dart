/// Modelagem de Failures para a camada de apresentação e ViewModel.
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => '$runtimeType: $message';
}

class InsufficientFundsFailure extends Failure {
  const InsufficientFundsFailure([String message = 'Saldo insuficiente para efetuar o pagamento.'])
      : super(message, code: 'INSUFFICIENT_FUNDS');
}

class IdempotencyConflictFailure extends Failure {
  const IdempotencyConflictFailure([String message = 'Esta operação já foi processada anteriormente.'])
      : super(message, code: 'IDEMPOTENCY_CONFLICT');
}

class LedgerIntegrityFailure extends Failure {
  const LedgerIntegrityFailure([String message = 'Erro crítico de integridade contábil. A operação foi cancelada.'])
      : super(message, code: 'LEDGER_INTEGRITY_VIOLATION');
}

class AccountNotFoundFailure extends Failure {
  const AccountNotFoundFailure([String message = 'Conta bancária informada não existe.'])
      : super(message, code: 'ACCOUNT_NOT_FOUND');
}

class AuthFailure extends Failure {
  const AuthFailure([String message = 'Usuário ou senha inválidos.'])
      : super(message, code: 'AUTH_FAILED');
}

class InvalidPinFailure extends Failure {
  const InvalidPinFailure([String message = 'Senha transacional incorreta.'])
      : super(message, code: 'INVALID_PIN');
}

class PixKeyNotFoundFailure extends Failure {
  const PixKeyNotFoundFailure([String message = 'Chave PIX não encontrada.'])
      : super(message, code: 'PIX_KEY_NOT_FOUND');
}

class ExternalServiceFailure extends Failure {
  const ExternalServiceFailure(String message, {String? code})
      : super(message, code: code ?? 'EXTERNAL_SERVICE_FAILURE');
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Sem conexão com a internet. Verifique sua rede e tente novamente.'])
      : super(message, code: 'NETWORK_ERROR');
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Falha de comunicação com o servidor remoto. Tente novamente mais tarde.'])
      : super(message, code: 'SERVER_ERROR');
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([String message = 'Ocorreu um erro ao acessar o banco de dados.'])
      : super(message, code: 'DATABASE_FAILURE');
}
