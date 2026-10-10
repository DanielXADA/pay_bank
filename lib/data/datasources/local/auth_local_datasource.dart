import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/errors/exceptions.dart';

class AuthLocalDataSource {
  final LocalAuthentication _localAuth;

  static const String keyLastUser = 'ultimo_usuario';
  static const String keyActiveSession = 'sessao_ativa';
  static const String keyBiometricEnabled = 'biometria_ativa';

  AuthLocalDataSource({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  /// Salva o último nome de usuário logado no dispositivo.
  Future<void> saveLastUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyLastUser, username);
  }

  /// Recupera o último nome de usuário logado.
  Future<String?> getLastUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyLastUser);
  }

  /// Salva a sessão ativa.
  Future<void> saveActiveSession(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyActiveSession, username);
    await prefs.setString(keyLastUser, username);
  }

  /// Recupera o usuário da sessão ativa.
  Future<String?> getActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyActiveSession);
  }

  /// Limpa a sessão ativa (Logout).
  Future<void> clearActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyActiveSession);
  }

  /// Verifica se o dispositivo possui hardware e suporte a biometria.
  Future<bool> isBiometricsAvailable() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return isSupported || canCheck;
    } catch (_) {
      return false;
    }
  }

  /// Dispara o modal nativo de autenticação biométrica do sistema operacional.
  Future<bool> authenticateWithBiometrics({String? reason}) async {
    try {
      final canAuth = await isBiometricsAvailable();
      if (!canAuth) {
        throw const AuthenticationException('Biometria ou bloqueio de tela não disponível no dispositivo.');
      }

      return await _localAuth.authenticate(
        localizedReason: reason ?? 'Confirme sua identidade para acessar sua conta PayBank',
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );
    } catch (e) {
      if (e is AuthenticationException) rethrow;
      throw AuthenticationException('Falha no processo de autenticação biométrica: $e');
    }
  }
}
