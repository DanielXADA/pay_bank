import 'package:sqflite/sqflite.dart' as sqflite;
import '../../core/errors/exceptions.dart';
import '../../core/value_objects/money.dart';
import '../../database/db_helper.dart';
import '../../domain/entities/entry.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/i_transaction_repository.dart';
import '../models/entry_model.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements ITransactionRepository {
  final DatabaseHelper _dbHelper;

  TransactionRepositoryImpl({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<Transaction> executePixTransfer({
    required String idempotencyKey,
    required int senderAccountId,
    required int receiverAccountId,
    required Money amount,
    String? description,
  }) async {
    if (senderAccountId == receiverAccountId) {
      throw ArgumentError('Conta de origem e destino não podem ser as mesmas.');
    }
    if (amount.isNegative || amount.isZero) {
      throw ArgumentError('O valor da transferência deve ser estritamente maior que zero.');
    }

    // 1. Verificação prévia de idempotência fora do lock
    final existingTx = await getTransactionByIdempotencyKey(idempotencyKey);
    if (existingTx != null) {
      if (existingTx.status == TransactionStatus.completed) {
        return existingTx; // Retorno idempotente (evita debitar duas vezes)
      } else {
        throw const IdempotencyConflictException();
      }
    }

    final db = await _dbHelper.database;

    // 2. Execução estritamente atômica dentro de db.transaction
    return await db.transaction<Transaction>((txn) async {
      // 2.1. Segunda checagem de idempotência com lock da transação
      final existingWithinTx = await _findTransactionByIdempotencyKey(txn, idempotencyKey);
      if (existingWithinTx != null) {
        return existingWithinTx.toDomain();
      }

      // 2.2. Validação atômica de saldo
      final senderBalanceCents = await _dbHelper.getSnapshotBalanceCents(senderAccountId, txn);
      if (senderBalanceCents < amount.cents) {
        throw const InsufficientFundsException();
      }

      // 2.3. Resgate de metadados para auditoria e comprovantes
      final senderInfo = await _getAccountUserInfo(txn, senderAccountId);
      final receiverInfo = await _getAccountUserInfo(txn, receiverAccountId);

      final now = DateTime.now();
      final nowIso = now.toIso8601String();
      final txId = 'TX-PIX-${now.millisecondsSinceEpoch}-${idempotencyKey.hashCode.abs().toString().padLeft(6, '0')}';
      final txDescription = description ?? 'Transferência PIX para ${receiverInfo?['nome'] ?? 'Destinatário'}';

      // 2.4. Inserção do Agregado da Transação (com UNIQUE idempotency_key)
      final txModel = TransactionModel(
        id: txId,
        idempotencyKey: idempotencyKey,
        type: 'PIX_TRANSFER',
        status: 'COMPLETED',
        amountCents: amount.cents,
        description: txDescription,
        senderAccountId: senderAccountId,
        receiverAccountId: receiverAccountId,
        senderName: senderInfo?['nome'] as String?,
        receiverName: receiverInfo?['nome'] as String?,
        receiverCpf: receiverInfo?['cpf'] as String?,
        createdAt: nowIso,
      );

      try {
        await txn.insert('transactions', txModel.toMap());
      } on sqflite.DatabaseException catch (e) {
        if (e.isUniqueConstraintError()) {
          throw const IdempotencyConflictException();
        }
        rethrow;
      }

      // 2.5. Inserção das Partidas Dobradas (Entries)
      // Débito no Pagador (Valor negativo no saldo contábil)
      final debitEntryId = await txn.insert('entries', {
        'transaction_id': txId,
        'account_id': senderAccountId,
        'type': 'DEBIT',
        'amount_cents': amount.cents,
        'signed_amount_cents': -amount.cents,
        'description': 'PIX para ${receiverInfo?['nome'] ?? 'Destinatário'}',
        'created_at': nowIso,
      });

      // Crédito no Recebedor (Valor positivo no saldo contábil)
      final creditEntryId = await txn.insert('entries', {
        'transaction_id': txId,
        'account_id': receiverAccountId,
        'type': 'CREDIT',
        'amount_cents': amount.cents,
        'signed_amount_cents': amount.cents,
        'description': 'PIX recebido de ${senderInfo?['nome'] ?? 'Pagador'}',
        'created_at': nowIso,
      });

      // 2.6. Atualização atômica dos Snapshots CQRS
      await txn.rawUpdate('''
        UPDATE account_balances_snapshot 
        SET balance_cents = balance_cents - ?, 
            last_entry_id = ?, 
            updated_at = ? 
        WHERE account_id = ?
      ''', [amount.cents, debitEntryId, nowIso, senderAccountId]);

      await txn.rawUpdate('''
        UPDATE account_balances_snapshot 
        SET balance_cents = balance_cents + ?, 
            last_entry_id = ?, 
            updated_at = ? 
        WHERE account_id = ?
      ''', [amount.cents, creditEntryId, nowIso, receiverAccountId]);

      // 2.7. Sincronização com tabelas legadas para garantir compatibilidade com Views antigas
      if (senderInfo != null && receiverInfo != null) {
        final dataFormatada = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} às ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

        // Comprovante de Saída
        await txn.insert('transferencias', {
          'id_usuario': senderInfo['user_id'],
          'tipo': 'SAIDA',
          'recebedor': receiverInfo['nome'] ?? '',
          'pagador': senderInfo['nome'] ?? '',
          'cpf_recebedor': receiverInfo['cpf'] ?? '',
          'agencia_recebedor': receiverInfo['agencia'] ?? '',
          'conta_recebedor': receiverInfo['account_number'] ?? '',
          'valor': amount.toDouble(),
          'data': dataFormatada,
          'id_transacao': txId,
        });

        // Comprovante de Entrada
        await txn.insert('transferencias', {
          'id_usuario': receiverInfo['user_id'],
          'tipo': 'ENTRADA',
          'recebedor': receiverInfo['nome'] ?? '',
          'pagador': senderInfo['nome'] ?? '',
          'cpf_recebedor': receiverInfo['cpf'] ?? '',
          'agencia_recebedor': receiverInfo['agencia'] ?? '',
          'conta_recebedor': receiverInfo['account_number'] ?? '',
          'valor': amount.toDouble(),
          'data': dataFormatada,
          'id_transacao': txId,
        });

        // Sincroniza coluna saldo legada de usuários
        await txn.rawUpdate(
          'UPDATE usuarios SET saldo = saldo - ? WHERE id = ?',
          [amount.toDouble(), senderInfo['user_id']],
        );
        await txn.rawUpdate(
          'UPDATE usuarios SET saldo = saldo + ? WHERE id = ?',
          [amount.toDouble(), receiverInfo['user_id']],
        );
      }

      final entries = [
        Entry(
          id: debitEntryId,
          transactionId: txId,
          accountId: senderAccountId,
          type: EntryType.debit,
          amount: amount,
          description: 'PIX para ${receiverInfo?['nome']}',
          createdAt: now,
        ),
        Entry(
          id: creditEntryId,
          transactionId: txId,
          accountId: receiverAccountId,
          type: EntryType.credit,
          amount: amount,
          description: 'PIX recebido de ${senderInfo?['nome']}',
          createdAt: now,
        ),
      ];

      return txModel.toDomain().copyWith(entries: entries);
    });
  }

  @override
  Future<Transaction> executeDeposit({
    required String idempotencyKey,
    required int accountId,
    required Money amount,
    String? description,
  }) async {
    if (amount.isNegative || amount.isZero) {
      throw ArgumentError('O valor do depósito deve ser estritamente maior que zero.');
    }

    // 1. Checagem de Idempotência prévia
    final existingTx = await getTransactionByIdempotencyKey(idempotencyKey);
    if (existingTx != null) {
      return existingTx;
    }

    final db = await _dbHelper.database;

    // 2. Execução atômica dentro de db.transaction
    return await db.transaction<Transaction>((txn) async {
      final existingWithinTx = await _findTransactionByIdempotencyKey(txn, idempotencyKey);
      if (existingWithinTx != null) {
        return existingWithinTx.toDomain();
      }

      final userInfo = await _getAccountUserInfo(txn, accountId);
      final now = DateTime.now();
      final nowIso = now.toIso8601String();
      final txId = 'TX-DEP-${now.millisecondsSinceEpoch}-${idempotencyKey.hashCode.abs().toString().padLeft(6, '0')}';
      final txDescription = description ?? 'Depósito em Conta Corrente';

      // Transação contra a conta Caixa/Cofre do Banco
      final txModel = TransactionModel(
        id: txId,
        idempotencyKey: idempotencyKey,
        type: 'DEPOSIT',
        status: 'COMPLETED',
        amountCents: amount.cents,
        description: txDescription,
        senderAccountId: DatabaseHelper.systemVaultAccountId,
        receiverAccountId: accountId,
        senderName: 'PayBank Tesouraria',
        receiverName: userInfo?['nome'] as String?,
        receiverCpf: userInfo?['cpf'] as String?,
        createdAt: nowIso,
      );

      await txn.insert('transactions', txModel.toMap());

      // Lançamento de Débito no Cofre do Banco (-amount)
      final debitEntryId = await txn.insert('entries', {
        'transaction_id': txId,
        'account_id': DatabaseHelper.systemVaultAccountId,
        'type': 'DEBIT',
        'amount_cents': amount.cents,
        'signed_amount_cents': -amount.cents,
        'description': 'Saída de numerário para crédito em conta',
        'created_at': nowIso,
      });

      // Lançamento de Crédito na Conta do Cliente (+amount)
      final creditEntryId = await txn.insert('entries', {
        'transaction_id': txId,
        'account_id': accountId,
        'type': 'CREDIT',
        'amount_cents': amount.cents,
        'signed_amount_cents': amount.cents,
        'description': 'Depósito em conta corrente',
        'created_at': nowIso,
      });

      // Atualiza Snapshot CQRS
      await txn.rawUpdate('''
        UPDATE account_balances_snapshot 
        SET balance_cents = balance_cents - ?, 
            last_entry_id = ?, 
            updated_at = ? 
        WHERE account_id = ?
      ''', [amount.cents, debitEntryId, nowIso, DatabaseHelper.systemVaultAccountId]);

      await txn.rawUpdate('''
        UPDATE account_balances_snapshot 
        SET balance_cents = balance_cents + ?, 
            last_entry_id = ?, 
            updated_at = ? 
        WHERE account_id = ?
      ''', [amount.cents, creditEntryId, nowIso, accountId]);

      // Sincroniza histórico legado
      if (userInfo != null) {
        await txn.insert('transferencias', {
          'id_usuario': userInfo['user_id'],
          'tipo': 'ENTRADA',
          'recebedor': 'Depósito em Conta',
          'pagador': userInfo['nome'] ?? 'Próprio Titular',
          'valor': amount.toDouble(),
          'data': now.toString().substring(0, 19),
          'id_transacao': txId,
        });

        await txn.rawUpdate(
          'UPDATE usuarios SET saldo = saldo + ? WHERE id = ?',
          [amount.toDouble(), userInfo['user_id']],
        );
      }

      final entries = [
        Entry(
          id: debitEntryId,
          transactionId: txId,
          accountId: DatabaseHelper.systemVaultAccountId,
          type: EntryType.debit,
          amount: amount,
          description: 'Cofre do Banco',
          createdAt: now,
        ),
        Entry(
          id: creditEntryId,
          transactionId: txId,
          accountId: accountId,
          type: EntryType.credit,
          amount: amount,
          description: 'Depósito em conta',
          createdAt: now,
        ),
      ];

      return txModel.toDomain().copyWith(entries: entries);
    });
  }

  @override
  Future<List<Transaction>> getTransactionsForAccount(int accountId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'transactions',
      where: 'sender_account_id = ? OR receiver_account_id = ?',
      whereArgs: [accountId, accountId],
      orderBy: 'created_at DESC',
    );

    final List<Transaction> result = [];
    for (final row in rows) {
      final txId = row['id'] as String;
      final entryRows = await db.query(
        'entries',
        where: 'transaction_id = ?',
        whereArgs: [txId],
      );
      final entries = entryRows.map((e) => EntryModel.fromMap(e).toDomain()).toList();
      result.add(TransactionModel.fromMap(row).toDomain().copyWith(entries: entries));
    }

    return result;
  }

  @override
  Future<Transaction?> getTransactionByIdempotencyKey(String idempotencyKey) async {
    final db = await _dbHelper.database;
    final model = await _findTransactionByIdempotencyKey(db, idempotencyKey);
    return model?.toDomain();
  }

  Future<TransactionModel?> _findTransactionByIdempotencyKey(
    sqflite.DatabaseExecutor executor,
    String idempotencyKey,
  ) async {
    final rows = await executor.query(
      'transactions',
      where: 'idempotency_key = ?',
      whereArgs: [idempotencyKey],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final txRow = rows.first;
    final txId = txRow['id'] as String;

    final entryRows = await executor.query(
      'entries',
      where: 'transaction_id = ?',
      whereArgs: [txId],
    );

    final entries = entryRows.map((e) => EntryModel.fromMap(e)).toList();
    return TransactionModel.fromMap(txRow, entries);
  }

  Future<Map<String, dynamic>?> _getAccountUserInfo(
    sqflite.DatabaseExecutor executor,
    int accountId,
  ) async {
    final rows = await executor.rawQuery('''
      SELECT 
        a.id AS account_id,
        a.user_id,
        a.account_number,
        a.agency,
        u.nome,
        u.cpf,
        u.email
      FROM accounts a
      LEFT JOIN usuarios u ON a.user_id = u.id
      WHERE a.id = ?
      LIMIT 1
    ''', [accountId]);

    if (rows.isEmpty) return null;
    return rows.first;
  }
}
