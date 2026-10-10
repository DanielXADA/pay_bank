import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../core/errors/failures.dart';
import '../../core/value_objects/money.dart';
import '../../database/db_helper.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/i_account_repository.dart';
import '../../domain/repositories/i_transaction_repository.dart';
import '../../domain/repositories/i_user_repository.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';

/// ViewModel reativa (MVVM) responsável por gerenciar a tela principal (Home).
///
/// Obtém o saldo através de leituras ultrarrápidas de Snapshot CQRS,
/// reconcilia extratos com o Ledger e executa depósitos atômicos contra o cofre do banco.
class HomeViewModel extends ChangeNotifier {
  final IAccountRepository _accountRepository;
  final ITransactionRepository _transactionRepository;
  final IUserRepository _userRepository;
  final DatabaseHelper _dbHelper;

  bool _isLoading = true;
  bool _isDepositing = false;
  bool _isBalanceVisible = true;
  String? _errorMessage;
  String? _successMessage;

  User? _currentUser;
  Account? _currentAccount;
  Money _balance = const Money.zero();
  List<Transaction> _transactions = [];
  List<Map<String, dynamic>> _legacyTransfers = [];

  HomeViewModel({
    IAccountRepository? accountRepository,
    ITransactionRepository? transactionRepository,
    IUserRepository? userRepository,
    DatabaseHelper? dbHelper,
  })  : _accountRepository = accountRepository ?? AccountRepositoryImpl(),
        _transactionRepository = transactionRepository ?? TransactionRepositoryImpl(),
        _userRepository = userRepository ?? UserRepositoryImpl(),
        _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // Getters para a View observar
  bool get isLoading => _isLoading;
  bool get isDepositing => _isDepositing;
  bool get isBalanceVisible => _isBalanceVisible;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  User? get currentUser => _currentUser;
  Account? get currentAccount => _currentAccount;
  Money get balance => _balance;
  List<Transaction> get transactions => _transactions;
  List<Map<String, dynamic>> get legacyTransfers => _legacyTransfers;

  void toggleBalanceVisibility() {
    _isBalanceVisible = !_isBalanceVisible;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void clearSuccess() {
    if (_successMessage != null) {
      _successMessage = null;
      notifyListeners();
    }
  }

  /// Carrega os dados atualizados do correntista, saldo derivado e extrato contábil.
  Future<void> loadUserData(String username) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _userRepository.getUserByUsername(username);
      if (user == null || user.id == null) {
        _errorMessage = 'Não foi possível carregar os dados da conta.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _currentUser = user;

      // Obtém conta e saldo consolidado via Snapshot CQRS
      final account = await _accountRepository.getAccountByUserId(user.id!);
      _currentAccount = account;
      _balance = account.balance;

      // Carrega transações do Ledger e histórico compatível
      _transactions = await _transactionRepository.getTransactionsForAccount(account.id);
      _legacyTransfers = await _dbHelper.buscarTransferenciasDoUsuario(user.id!);

      _isLoading = false;
      notifyListeners();
    } on Failure catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Falha ao sincronizar dados da conta: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Realiza depósito virtual atômico contra a conta cofre do banco (System Vault).
  Future<bool> deposit(double amountValue) async {
    if (_currentAccount == null || _currentUser == null) {
      _errorMessage = 'Conta de destino não inicializada.';
      notifyListeners();
      return false;
    }

    if (amountValue <= 0) {
      _errorMessage = 'O valor do depósito deve ser maior que zero.';
      notifyListeners();
      return false;
    }

    _isDepositing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final amount = Money.fromDouble(amountValue);
      final random = math.Random().nextInt(999999);
      final idempotencyKey = 'dep_${_currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}_$random';

      await _transactionRepository.executeDeposit(
        idempotencyKey: idempotencyKey,
        accountId: _currentAccount!.id,
        amount: amount,
        description: 'Depósito em conta corrente',
      );

      // Reconcilia e atualiza saldo via Snapshot CQRS
      _balance = await _accountRepository.getBalance(_currentAccount!.id);
      _transactions = await _transactionRepository.getTransactionsForAccount(_currentAccount!.id);
      _legacyTransfers = await _dbHelper.buscarTransferenciasDoUsuario(_currentUser!.id!);

      _successMessage = 'Depósito realizado com sucesso!';
      _isDepositing = false;
      notifyListeners();
      return true;
    } on Failure catch (e) {
      _errorMessage = e.message;
      _isDepositing = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Erro ao processar depósito: $e';
      _isDepositing = false;
      notifyListeners();
      return false;
    }
  }
}
