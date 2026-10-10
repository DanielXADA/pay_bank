import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../core/errors/failures.dart';
import '../../core/value_objects/money.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/i_address_repository.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/repositories/i_user_repository.dart';
import '../../data/repositories/address_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';

/// ViewModel reativa (MVVM) responsável por orquestrar todo o ciclo de vida
/// de autenticação, login biométrico, consulta de CEP e cadastro de correntistas.
class AuthViewModel extends ChangeNotifier {
  final IAuthRepository _authRepository;
  final IUserRepository _userRepository;
  final IAddressRepository _addressRepository;

  bool _isLoading = false;
  bool _isSearchingCep = false;
  String? _errorMessage;
  String? _successMessage;
  User? _currentUser;
  Address? _searchedAddress;
  String? _lastSavedUsername;

  AuthViewModel({
    IAuthRepository? authRepository,
    IUserRepository? userRepository,
    IAddressRepository? addressRepository,
  })  : _authRepository = authRepository ?? AuthRepositoryImpl(),
        _userRepository = userRepository ?? UserRepositoryImpl(),
        _addressRepository = addressRepository ?? AddressRepositoryImpl();

  // Getters para a View observar o estado
  bool get isLoading => _isLoading;
  bool get isSearchingCep => _isSearchingCep;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  User? get currentUser => _currentUser;
  Address? get searchedAddress => _searchedAddress;
  String? get lastSavedUsername => _lastSavedUsername;

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

  /// Carrega o último usuário lembrado no dispositivo.
  Future<void> loadLastSavedUsername() async {
    try {
      if (_authRepository is AuthRepositoryImpl) {
        _lastSavedUsername = await _authRepository.getLastUsername();
      } else {
        _lastSavedUsername = await _authRepository.getCurrentSessionUsername();
      }
      notifyListeners();
    } catch (_) {
      // Ignora erro silencioso no preenchimento do campo
    }
  }

  /// Realiza o login com nome de usuário e senha.
  Future<bool> login(String username, String password) async {
    final cleanUsername = username.trim();
    final cleanPassword = password.trim();

    if (cleanUsername.isEmpty || cleanPassword.isEmpty) {
      _errorMessage = 'Por favor, preencha o usuário e a senha.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _authRepository.login(
        username: cleanUsername,
        password: cleanPassword,
      );

      if (user != null) {
        _currentUser = user;
        _lastSavedUsername = user.username;
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Usuário ou senha inválidos.';
        _setLoading(false);
        return false;
      }
    } on Failure catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Falha inesperada durante o login. Tente novamente.';
      _setLoading(false);
      return false;
    }
  }

  /// Realiza a autenticação biométrica (Face ID / Digital).
  Future<bool> loginWithBiometrics() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await loadLastSavedUsername();
      final username = _lastSavedUsername;

      if (username == null || username.isEmpty) {
        _errorMessage = 'Faça login com usuário e senha pelo menos uma vez antes de usar biometria.';
        _setLoading(false);
        return false;
      }

      final authenticated = await _authRepository.authenticateWithBiometrics();
      if (!authenticated) {
        _setLoading(false);
        return false;
      }

      final user = await _userRepository.getUserByUsername(username);
      if (user == null) {
        _errorMessage = 'Usuário cadastrado não foi localizado.';
        _setLoading(false);
        return false;
      }

      await _authRepository.saveSession(username);
      _currentUser = user;
      _setLoading(false);
      return true;
    } on Failure catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Erro ao processar biometria: $e';
      _setLoading(false);
      return false;
    }
  }

  /// Consulta o endereço na API do ViaCEP via Repositório (ACL).
  Future<bool> searchCep(String rawCep) async {
    final sanitizedCep = rawCep.replaceAll(RegExp(r'\D'), '');

    if (sanitizedCep.length != 8) {
      _errorMessage = 'Digite um CEP válido com 8 dígitos.';
      notifyListeners();
      return false;
    }

    _isSearchingCep = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final address = await _addressRepository.getAddressByCep(sanitizedCep);
      _searchedAddress = address;
      _isSearchingCep = false;
      notifyListeners();
      return true;
    } on Failure catch (e) {
      _errorMessage = e.message;
      _searchedAddress = null;
      _isSearchingCep = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Não foi possível localizar o CEP informado.';
      _searchedAddress = null;
      _isSearchingCep = false;
      notifyListeners();
      return false;
    }
  }

  /// Cadastra um novo correntista com provisionamento de conta no Core Banking.
  Future<bool> registerUser({
    required String name,
    required String username,
    required String email,
    required String phone,
    required String cpf,
    required String birthDate,
    required String cep,
    required String street,
    required String number,
    required String neighborhood,
    required String city,
    required String state,
    required String password,
    required String transactionPassword,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final random = math.Random();
      final accountNumber = '${random.nextInt(90000) + 10000}-${random.nextInt(9)}';

      String complementPart = '';
      if (number.isNotEmpty) {
        complementPart = 'Nº $number';
      }

      final address = Address(
        cep: cep,
        street: street,
        complement: complementPart,
        neighborhood: neighborhood,
        city: city,
        state: state,
      );

      final newUser = User(
        name: name.trim(),
        username: username.trim(),
        email: email.trim(),
        phone: phone.trim(),
        cpf: cpf.trim(),
        birthDate: birthDate.trim(),
        address: address,
        agency: '0001',
        accountNumber: accountNumber,
        isCpfKeyActive: true,
        isEmailKeyActive: false,
        isPhoneKeyActive: false,
      );

      await _userRepository.registerUser(
        user: newUser,
        password: password.trim(),
        transactionPassword: transactionPassword.trim(),
        initialDeposit: const Money.zero(),
      );

      _successMessage = 'Conta criada com sucesso! Faça seu Login.';
      _setLoading(false);
      return true;
    } on Failure catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Falha inesperada ao criar conta: $e';
      _setLoading(false);
      return false;
    }
  }

  /// Redefine a senha de acesso após validação cadastral segura.
  Future<bool> resetPassword({
    required String username,
    required String cpf,
    required String birthDate,
    required String newPassword,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _userRepository.getUserByUsername(username.trim());

      if (user == null || user.cpf != cpf.trim() || user.birthDate != birthDate.trim()) {
        _errorMessage = 'Dados de validação incorretos ou usuário não encontrado.';
        _setLoading(false);
        return false;
      }

      await _authRepository.changePassword(
        userId: user.id!,
        currentPassword: '', // Caso de redefinição autorizada
        newPassword: newPassword.trim(),
      );

      _successMessage = 'Senha de acesso redefinida com sucesso!';
      _setLoading(false);
      return true;
    } on Failure catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Falha ao redefinir senha: $e';
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
