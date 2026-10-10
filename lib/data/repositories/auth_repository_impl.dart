import '../../core/errors/failures.dart';
import '../../database/db_helper.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../models/account_model.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final DatabaseHelper _dbHelper;
  final AuthLocalDataSource _authLocalDataSource;

  AuthRepositoryImpl({
    DatabaseHelper? dbHelper,
    AuthLocalDataSource? authLocalDataSource,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _authLocalDataSource = authLocalDataSource ?? AuthLocalDataSource();

  @override
  Future<User?> login({
    required String username,
    required String password,
  }) async {
    try {
      final userMap = await _dbHelper.buscarUsuarioPorLogin(username);

      if (userMap == null || userMap['senha'] != password) {
        throw const AuthFailure('Usuário ou senha incorretos.');
      }

      final userId = userMap['id'] as int;
      await _authLocalDataSource.saveActiveSession(username);

      // Carrega dados da conta associada
      final account = await _loadUserAccount(userId);
      return UserModel.fromMap(userMap).toDomain(account);
    } on Failure {
      rethrow;
    } catch (e) {
      throw DatabaseFailure('Erro durante autenticação: $e');
    }
  }

  @override
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _authLocalDataSource.authenticateWithBiometrics(
        reason: 'Confirme sua biometria para acessar sua conta PayBank',
      );
    } catch (e) {
      throw AuthFailure('Falha ao autenticar com biometria: $e');
    }
  }

  @override
  Future<bool> verifyTransactionPin({
    required int userId,
    required String pin,
  }) async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.query(
        'usuarios',
        columns: ['senha_transacao'],
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (rows.isEmpty) {
        throw const AuthFailure('Usuário não localizado.');
      }

      final storedPin = rows.first['senha_transacao'] as String?;
      if (storedPin == null || storedPin.isEmpty || storedPin != pin) {
        throw const InvalidPinFailure('Senha transacional incorreta.');
      }

      return true;
    } on Failure {
      rethrow;
    } catch (e) {
      throw DatabaseFailure('Falha ao validar senha transacional: $e');
    }
  }

  @override
  Future<void> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.query(
        'usuarios',
        columns: ['senha'],
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (rows.isEmpty || rows.first['senha'] != currentPassword) {
        throw const AuthFailure('Senha atual informada é inválida.');
      }

      await db.update(
        'usuarios',
        {'senha': newPassword},
        where: 'id = ?',
        whereArgs: [userId],
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw DatabaseFailure('Falha ao alterar senha de acesso: $e');
    }
  }

  @override
  Future<void> changeTransactionPin({
    required int userId,
    required String currentPin,
    required String newPin,
  }) async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.query(
        'usuarios',
        columns: ['senha_transacao'],
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (rows.isNotEmpty) {
        final stored = rows.first['senha_transacao'] as String?;
        // Permite cadastrar pela primeira vez caso não possua PIN ainda
        if (stored != null && stored.isNotEmpty && stored != currentPin) {
          throw const InvalidPinFailure('Senha transacional atual incorreta.');
        }
      }

      await db.update(
        'usuarios',
        {'senha_transacao': newPin},
        where: 'id = ?',
        whereArgs: [userId],
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw DatabaseFailure('Falha ao alterar senha transacional: $e');
    }
  }

  @override
  Future<void> saveSession(String username) async {
    await _authLocalDataSource.saveActiveSession(username);
  }

  @override
  Future<String?> getCurrentSessionUsername() async {
    return await _authLocalDataSource.getActiveSession();
  }

  /// Recupera o último usuário gravado para preenchimento automático na tela de login.
  Future<String?> getLastUsername() async {
    return await _authLocalDataSource.getLastUsername();
  }

  @override
  Future<void> logout() async {
    await _authLocalDataSource.clearActiveSession();
  }

  Future<Account> _loadUserAccount(int userId) async {
    final db = await _dbHelper.database;
    final accountId = await _dbHelper.getOrCreateAccountIdForUser(userId, executor: db);
    final rows = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );

    final balanceCents = await _dbHelper.getSnapshotBalanceCents(accountId, db);
    return AccountModel.fromMap(rows.first, balanceCents).toDomain();
  }
}
