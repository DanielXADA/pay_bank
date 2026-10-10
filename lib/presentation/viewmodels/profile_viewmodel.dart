import 'package:flutter/foundation.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/i_address_repository.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/repositories/i_user_repository.dart';
import '../../data/repositories/address_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';

enum KycTier {
  basic, // Nível 1 - Conta Regular
  verified, // Nível 2 - KYC Completo (Fotos + Biometria)
}

/// ViewModel reativa (MVVM) responsável pela gestão de Perfil, Segurança bancária (KYC) e Chaves PIX.
class ProfileViewModel extends ChangeNotifier {
  final IUserRepository _userRepository;
  final IAuthRepository _authRepository;
  final IAddressRepository _addressRepository;

  bool _isLoading = false;
  bool _isSearchingCep = false;
  String? _errorMessage;
  String? _successMessage;
  User? _currentUser;
  Address? _searchedAddress;

  ProfileViewModel({
    IUserRepository? userRepository,
    IAuthRepository? authRepository,
    IAddressRepository? addressRepository,
  })  : _userRepository = userRepository ?? UserRepositoryImpl(),
        _authRepository = authRepository ?? AuthRepositoryImpl(),
        _addressRepository = addressRepository ?? AddressRepositoryImpl();

  // Getters
  bool get isLoading => _isLoading;
  bool get isSearchingCep => _isSearchingCep;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  User? get currentUser => _currentUser;
  Address? get searchedAddress => _searchedAddress;

  // Status de Ciclo de Vida da Conta e Regras de Core Banking (KYC)
  String get accountLifecycleStatus => 'Conta Ativa & Regular';

  KycTier get kycTier {
    if (_currentUser == null) return KycTier.basic;
    final temFoto = _currentUser!.facePhotoPath != null && _currentUser!.facePhotoPath!.isNotEmpty;
    return temFoto ? KycTier.verified : KycTier.basic;
  }

  String get kycStatusDescription {
    switch (kycTier) {
      case KycTier.verified:
        return 'KYC Nível 2 (Identidade Verificada)';
      case KycTier.basic:
        return 'KYC Nível 1 (Cadastro Básico)';
    }
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

  /// Carrega os dados atualizados do correntista.
  Future<void> loadUser(String username) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _userRepository.getUserByUsername(username);
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
    } on Failure catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Falha ao carregar dados do usuário: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Busca endereço na API do ViaCEP via Repositório (ACL).
  Future<bool> searchCep(String rawCep) async {
    final cleanCep = rawCep.replaceAll(RegExp(r'\D'), '');
    if (cleanCep.length != 8) {
      _errorMessage = 'Digite um CEP válido com 8 números.';
      notifyListeners();
      return false;
    }

    _isSearchingCep = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final address = await _addressRepository.getAddressByCep(cleanCep);
      _searchedAddress = address;
      _isSearchingCep = false;
      notifyListeners();
      return true;
    } on Failure catch (e) {
      _errorMessage = e.message;
      _isSearchingCep = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Erro ao consultar o CEP.';
      _isSearchingCep = false;
      notifyListeners();
      return false;
    }
  }

  /// Atualiza foto de perfil e preserva no repositório.
  Future<void> updateFacePhoto(String photoPath) async {
    if (_currentUser == null) return;
    try {
      final updated = _currentUser!.copyWith(facePhotoPath: photoPath);
      await _userRepository.updateUser(updated);
      _currentUser = updated;
      _successMessage = 'Foto de perfil atualizada!';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao atualizar foto: $e';
      notifyListeners();
    }
  }

  /// Remove foto de perfil.
  Future<void> removeFacePhoto() async {
    if (_currentUser == null) return;
    try {
      final updated = _currentUser!.copyWith(facePhotoPath: '');
      await _userRepository.updateUser(updated);
      _currentUser = updated;
      _successMessage = 'Foto de perfil removida.';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao remover foto: $e';
      notifyListeners();
    }
  }

  /// Atualiza preferências e status de chaves PIX.
  Future<bool> updatePixKeys({
    required bool isCpfActive,
    required bool isEmailActive,
    required bool isPhoneActive,
    String? randomKey,
  }) async {
    if (_currentUser == null || _currentUser!.id == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _userRepository.updatePixKeys(
        userId: _currentUser!.id!,
        isCpfActive: isCpfActive,
        isEmailActive: isEmailActive,
        isPhoneActive: isPhoneActive,
      );

      if (randomKey != null) {
        final updated = _currentUser!.copyWith(
          randomPixKey: randomKey,
          isCpfKeyActive: isCpfActive,
          isEmailKeyActive: isEmailActive,
          isPhoneKeyActive: isPhoneActive,
        );
        await _userRepository.updateUser(updated);
        _currentUser = updated;
      } else {
        _currentUser = _currentUser!.copyWith(
          isCpfKeyActive: isCpfActive,
          isEmailKeyActive: isEmailActive,
          isPhoneKeyActive: isPhoneActive,
        );
      }

      _successMessage = 'Chaves PIX atualizadas com sucesso!';
      _isLoading = false;
      notifyListeners();
      return true;
    } on Failure catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar chaves PIX: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Atualiza dados cadastrais.
  Future<bool> updateProfileData({
    required String name,
    required String email,
    required String phone,
    required String cep,
    required String fullAddress,
  }) async {
    if (_currentUser == null || _currentUser!.id == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedAddress = Address(
        cep: cep,
        street: fullAddress,
        neighborhood: '',
        city: '',
        state: '',
      );

      final updatedUser = _currentUser!.copyWith(
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        address: updatedAddress,
      );

      await _userRepository.updateUser(updatedUser);
      _currentUser = updatedUser;

      _successMessage = 'Dados cadastrais salvos com sucesso!';
      _isLoading = false;
      notifyListeners();
      return true;
    } on Failure catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Falha ao salvar dados cadastrais: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Valida senha de acesso atual antes de autorizar edição sensível.
  Future<bool> verifyCurrentPassword(String password) async {
    if (_currentUser == null) return false;
    try {
      final user = await _authRepository.login(
        username: _currentUser!.username,
        password: password,
      );
      return user != null;
    } catch (_) {
      return false;
    }
  }

  /// Altera senha de acesso de login (8 dígitos).
  Future<bool> changeAccessPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null || _currentUser!.id == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.changePassword(
        userId: _currentUser!.id!,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      _successMessage = 'Senha de acesso alterada com sucesso!';
      _isLoading = false;
      notifyListeners();
      return true;
    } on Failure catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Falha ao alterar senha de acesso: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Altera PIN transacional (6 números).
  Future<bool> changeTransactionPin({
    required String currentPin,
    required String newPin,
  }) async {
    if (_currentUser == null || _currentUser!.id == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.changeTransactionPin(
        userId: _currentUser!.id!,
        currentPin: currentPin,
        newPin: newPin,
      );

      _successMessage = 'Senha transacional (PIN) alterada com sucesso!';
      _isLoading = false;
      notifyListeners();
      return true;
    } on Failure catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Falha ao alterar senha de transação: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Valida o PIN transacional do usuário autenticado no momento.
  Future<bool> verifyTransactionPin(String pin) async {
    if (_currentUser == null || _currentUser!.id == null) return false;
    try {
      return await _authRepository.verifyTransactionPin(
        userId: _currentUser!.id!,
        pin: pin,
      );
    } catch (_) {
      return false;
    }
  }
}

