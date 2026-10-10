import '../../core/errors/exceptions.dart';
import '../../core/value_objects/money.dart';
import '../../database/db_helper.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/entry.dart';
import '../../domain/repositories/i_account_repository.dart';
import '../models/account_model.dart';
import '../models/entry_model.dart';

class AccountRepositoryImpl implements IAccountRepository {
  final DatabaseHelper _dbHelper;

  AccountRepositoryImpl({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<Account> getAccountByUserId(int userId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'accounts',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (rows.isEmpty) {
      // Provisiona conta caso ainda não exista
      final accountId = await _dbHelper.getOrCreateAccountIdForUser(userId);
      return await getAccountById(accountId);
    }

    final row = rows.first;
    final accountId = row['id'] as int;
    final balanceCents = await _dbHelper.getSnapshotBalanceCents(accountId, db);

    return AccountModel.fromMap(row, balanceCents).toDomain();
  }

  @override
  Future<Account> getAccountById(int accountId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [accountId],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw const AccountNotFoundException();
    }

    final row = rows.first;
    final balanceCents = await _dbHelper.getSnapshotBalanceCents(accountId, db);

    return AccountModel.fromMap(row, balanceCents).toDomain();
  }

  @override
  Future<Money> getBalance(int accountId) async {
    final balanceCents = await _dbHelper.getSnapshotBalanceCents(accountId);
    return Money.fromCents(balanceCents);
  }

  @override
  Future<List<Entry>> getEntriesForAccount(int accountId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'entries',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'id DESC',
    );

    return rows.map((e) => EntryModel.fromMap(e).toDomain()).toList();
  }

  /// Reconcilia forçadamente o Snapshot com o Ledger somando todo o histórico.
  Future<Money> reconcileBalance(int accountId) async {
    final balanceCents = await _dbHelper.reconcileAccountBalance(accountId);
    return Money.fromCents(balanceCents);
  }
}
