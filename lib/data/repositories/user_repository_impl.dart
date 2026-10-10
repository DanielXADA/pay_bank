import 'package:sqflite/sqflite.dart' as sqflite;
import '../../core/errors/failures.dart';
import '../../core/value_objects/money.dart';
import '../../database/db_helper.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/i_user_repository.dart';
import '../models/account_model.dart';
import '../models/user_model.dart';
import 'transaction_repository_impl.dart';

class UserRepositoryImpl implements IUserRepository {
  final DatabaseHelper _dbHelper;
  final TransactionRepositoryImpl _transactionRepository;

  UserRepositoryImpl({
    DatabaseHelper? dbHelper,
    TransactionRepositoryImpl? transactionRepository,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _transactionRepository = transactionRepository ?? TransactionRepositoryImpl(dbHelper: dbHelper);

  @override
  Future<User> registerUser({
    required User user,
    required String password,
    required String transactionPassword,
    Money? initialDeposit,
  }) async {
    try {
      final db = await _dbHelper.database;

      // 1. Validação prévia de duplicidade de CPF ou nome de usuário
      final existingCpf = await db.query(
        'usuarios',
        where: 'cpf = ?',
        whereArgs: [user.cpf],
      );
      if (existingCpf.isNotEmpty) {
        throw const AuthFailure('Já existe uma conta cadastrada com este CPF.');
      }

      final existingUsername = await db.query(
        'usuarios',
        where: 'nome_usuario = ?',
        whereArgs: [user.username],
      );
      if (existingUsername.isNotEmpty) {
        throw const AuthFailure('Este nome de usuário já está em uso.');
      }

      // 2. Criação do correntista
      final userModel = UserModel.fromDomain(user);
      final userMap = userModel.toMap(
        password: password,
        transactionPassword: transactionPassword,
      );

      final userId = await db.insert('usuarios', userMap);

      // 3. Provisionamento da Conta Bancária no Core Banking
      final accountId = await _dbHelper.getOrCreateAccountIdForUser(
        userId,
        agency: user.agency,
        accountNumber: user.accountNumber,
        executor: db,
      );

      // 4. Se houver depósito inicial, registra lançamento no Ledger de forma atômica
      if (initialDeposit != null && initialDeposit.cents > 0) {
        await _transactionRepository.executeDeposit(
          idempotencyKey: 'initial_deposit_user_$userId',
          accountId: accountId,
          amount: initialDeposit,
          description: 'Depósito inicial de abertura de conta',
        );
      }

      final createdAccount = await _loadUserAccount(userId);
      return user.copyWith(
        id: userId,
        account: createdAccount,
      );
    } on Failure {
      rethrow;
    } on sqflite.DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw const AuthFailure('CPF ou Nome de Usuário já cadastrado.');
      }
      throw DatabaseFailure('Erro no banco de dados ao cadastrar correntista: $e');
    } catch (e) {
      throw DatabaseFailure('Falha inesperada no cadastro: $e');
    }
  }

  @override
  Future<User?> getUserById(int id) async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.query(
        'usuarios',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (rows.isEmpty) return null;

      final account = await _loadUserAccount(id);
      return UserModel.fromMap(rows.first).toDomain(account);
    } catch (e) {
      throw DatabaseFailure('Erro ao buscar usuário por ID: $e');
    }
  }

  @override
  Future<User?> getUserByUsername(String username) async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.query(
        'usuarios',
        where: 'nome_usuario = ?',
        whereArgs: [username],
        limit: 1,
      );

      if (rows.isEmpty) return null;

      final userId = rows.first['id'] as int;
      final account = await _loadUserAccount(userId);
      return UserModel.fromMap(rows.first).toDomain(account);
    } catch (e) {
      throw DatabaseFailure('Erro ao buscar usuário por login: $e');
    }
  }

  @override
  Future<User?> getUserByPixKey({
    required String type,
    required String key,
  }) async {
    try {
      final rawUser = await _dbHelper.buscarUsuarioPorChavePix(
        tipo: type,
        chave: key,
      );

      if (rawUser == null) {
        throw const PixKeyNotFoundFailure();
      }

      final userId = rawUser['id'] as int;
      final account = await _loadUserAccount(userId);
      return UserModel.fromMap(rawUser).toDomain(account);
    } on Failure {
      rethrow;
    } catch (e) {
      throw DatabaseFailure('Erro ao pesquisar destinatário via chave PIX: $e');
    }
  }

  @override
  Future<void> updateUser(User user) async {
    if (user.id == null) {
      throw ArgumentError('ID do usuário é obrigatório para atualização.');
    }

    try {
      final db = await _dbHelper.database;
      await db.update(
        'usuarios',
        {
          'nome': user.name,
          'email': user.email,
          'telefone': user.phone,
          'endereco': user.address.formattedOneLine,
          'cep': user.address.cep,
          'foto_rosto': user.facePhotoPath,
          'foto_documento': user.documentPhotoPath,
          'chave_aleatoria': user.randomPixKey,
        },
        where: 'id = ?',
        whereArgs: [user.id],
      );
    } catch (e) {
      throw DatabaseFailure('Erro ao atualizar cadastro do usuário: $e');
    }
  }

  @override
  Future<void> updatePixKeys({
    required int userId,
    required bool isCpfActive,
    required bool isEmailActive,
    required bool isPhoneActive,
  }) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        'usuarios',
        {
          'chave_cpf_ativa': isCpfActive ? 1 : 0,
          'chave_email_ativa': isEmailActive ? 1 : 0,
          'chave_telefone_ativa': isPhoneActive ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      throw DatabaseFailure('Erro ao atualizar preferências de chaves PIX: $e');
    }
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
