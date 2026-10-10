import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../core/errors/failures.dart';
import '../../core/value_objects/money.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/i_account_repository.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/repositories/i_transaction_repository.dart';
import '../../domain/repositories/i_user_repository.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';

/// ViewModel reativa (MVVM) responsável pelo fluxo completo de transferência PIX.
///
/// Implementa a validação de chave, geração de Chave de Idempotência exclusiva,
/// validação de PIN de segurança e orquestração da transação atômica no Ledger.
class TransferViewModel extends ChangeNotifier {
  final IUserRepository _userRepository;
  final IAccountRepository _accountRepository;
  final ITransactionRepository _transactionRepository;
  final IAuthRepository _authRepository;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  User? _senderUser;
  Account? _senderAccount;
  User? _receiverUser;
  Money? _transferAmount;
  String? _idempotencyKey;
  Transaction? _completedTransaction;

  TransferViewModel({
    IUserRepository? userRepository,
    IAccountRepository? accountRepository,
    ITransactionRepository? transactionRepository,
    IAuthRepository? authRepository,
  })  : _userRepository = userRepository ?? UserRepositoryImpl(),
        _accountRepository = accountRepository ?? AccountRepositoryImpl(),
        _transactionRepository = transactionRepository ?? TransactionRepositoryImpl(),
        _authRepository = authRepository ?? AuthRepositoryImpl();

  // Getters para a View
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  User? get senderUser => _senderUser;
  Account? get senderAccount => _senderAccount;
  User? get receiverUser => _receiverUser;
  Money? get transferAmount => _transferAmount;
  String? get idempotencyKey => _idempotencyKey;
  Transaction? get completedTransaction => _completedTransaction;

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Inicializa o pagador a partir do nome de usuário.
  Future<void> initSender(String username) async {
    try {
      final user = await _userRepository.getUserByUsername(username);
      if (user != null && user.id != null) {
        _senderUser = user;
        _senderAccount = await _accountRepository.getAccountByUserId(user.id!);
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Valida chave PIX, saldo disponível e prepara a revisão gerando Idempotency Key.
  Future<bool> validateAndReview({
    required String keyType,
    required String key,
    required double amountValue,
  }) async {
    final cleanKey = key.trim();

    if (cleanKey.isEmpty || amountValue <= 0) {
      _errorMessage = 'Por favor, preencha a chave e um valor válido.';
      notifyListeners();
      return false;
    }

    if (_senderUser == null || _senderAccount == null) {
      _errorMessage = 'Dados do pagador não carregados.';
      notifyListeners();
      return false;
    }

    final amount = Money.fromDouble(amountValue);

    // Validação preventiva de saldo
    if (_senderAccount!.balance < amount) {
      _errorMessage = 'Você não tem saldo suficiente para esse PIX!';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final receiver = await _userRepository.getUserByPixKey(
        type: keyType,
        key: cleanKey,
      );

      if (receiver == null || receiver.id == null) {
        _errorMessage = 'Chave PIX não encontrada ou inativa.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (receiver.id == _senderUser!.id) {
        _errorMessage = 'Você não pode fazer um PIX para você mesmo.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _receiverUser = receiver;
      _transferAmount = amount;

      // Geração de Chave de Idempotência única para a operação
      final random = math.Random().nextInt(999999);
      _idempotencyKey = 'pix_${_senderUser!.id}_${DateTime.now().millisecondsSinceEpoch}_$random';

      _isLoading = false;
      notifyListeners();
      return true;
    } on Failure catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Erro ao consultar chave PIX: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Valida a senha transacional (PIN) antes de enviar os fundos.
  Future<bool> verifyTransactionPin(String pin) async {
    if (_senderUser == null || _senderUser!.id == null) return false;

    _errorMessage = null;

    try {
      return await _authRepository.verifyTransactionPin(
        userId: _senderUser!.id!,
        pin: pin,
      );
    } on Failure catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Senha de transação incorreta.';
      notifyListeners();
      return false;
    }
  }

  /// Executa a transferência atômica com Ledger de partidas dobradas e idempotência.
  Future<bool> executeTransfer() async {
    if (_senderAccount == null || _receiverUser == null || _transferAmount == null) {
      _errorMessage = 'Dados de transferência inconsistentes.';
      notifyListeners();
      return false;
    }

    if (_idempotencyKey == null) {
      _errorMessage = 'Chave de idempotência não gerada.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final receiverAccount = await _accountRepository.getAccountByUserId(_receiverUser!.id!);

      final transaction = await _transactionRepository.executePixTransfer(
        idempotencyKey: _idempotencyKey!,
        senderAccountId: _senderAccount!.id,
        receiverAccountId: receiverAccount.id,
        amount: _transferAmount!,
        description: 'PIX para ${_receiverUser!.name}',
      );

      _completedTransaction = transaction;

      // Atualiza o saldo do pagador após o envio
      _senderAccount = await _accountRepository.getAccountByUserId(_senderUser!.id!);

      _successMessage = 'Transferência realizada com sucesso!';
      _isLoading = false;
      notifyListeners();
      return true;
    } on Failure catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Falha ao processar PIX: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _receiverUser = null;
    _transferAmount = null;
    _idempotencyKey = null;
    _completedTransaction = null;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
