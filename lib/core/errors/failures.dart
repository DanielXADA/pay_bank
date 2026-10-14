/// Modelagem de Failures para a camada de apresentação e ViewModel.
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => '$runtimeType: $message';
}

class InsufficientFundsFailure extends Failure {
  const InsufficientFundsFailure([super.message = 'Saldo insuficiente para efetuar o pagamento.'])
      : super(code: 'INSUFFICIENT_FUNDS');
}

class IdempotencyConflictFailure extends Failure {
  const IdempotencyConflictFailure([super.message = 'Esta operação já foi processada anteriormente.'])
      : super(code: 'IDEMPOTENCY_CONFLICT');
}

class LedgerIntegrityFailure extends Failure {
  const LedgerIntegrityFailure([super.message = 'Erro crítico de integridade contábil. A operação foi cancelada.'])
      : super(code: 'LEDGER_INTEGRITY_VIOLATION');
}

class AccountNotFoundFailure extends Failure {
  const AccountNotFoundFailure([super.message = 'Conta bancária informada não existe.'])
      : super(code: 'ACCOUNT_NOT_FOUND');
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Usuário ou senha inválidos.'])
      : super(code: 'AUTH_FAILED');
}

class InvalidPinFailure extends Failure {
  const InvalidPinFailure([super.message = 'Senha transacional incorreta.'])
      : super(code: 'INVALID_PIN');
}

class PixKeyNotFoundFailure extends Failure {
  const PixKeyNotFoundFailure([super.message = 'Chave PIX não encontrada.'])
      : super(code: 'PIX_KEY_NOT_FOUND');
}

class ExternalServiceFailure extends Failure {
  const ExternalServiceFailure(super.message, {String? code})
      : super(code: code ?? 'EXTERNAL_SERVICE_FAILURE');
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão com a internet. Verifique sua rede e tente novamente.'])
      : super(code: 'NETWORK_ERROR');
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Falha de comunicação com o servidor remoto. Tente novamente mais tarde.'])
      : super(code: 'SERVER_ERROR');
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Ocorreu um erro ao acessar o banco de dados.'])
      : super(code: 'DATABASE_FAILURE');
}
