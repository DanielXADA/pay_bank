import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static sqflite.Database? _database;

  static const int systemVaultAccountId = 1;
  static const int systemClearingAccountId = 2;

  DatabaseHelper._init();

  Future<sqflite.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sistema_usuarios.db');
    return _database!;
  }

  Future<sqflite.Database> _initDB(String filePath) async {
    final dbPath = await sqflite.getDatabasesPath();
    final path = join(dbPath, filePath);

    return await sqflite.openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(sqflite.Database db, int version) async {
    // 1. Tabela legada de usuários mantida para compatibilidade
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        nome_usuario TEXT NOT NULL UNIQUE,
        senha TEXT NOT NULL,
        senha_transacao TEXT,
        email TEXT NOT NULL,
        telefone TEXT NOT NULL,
        cpf TEXT NOT NULL UNIQUE,
        data_nascimento TEXT NOT NULL,
        endereco TEXT NOT NULL,
        cep TEXT NOT NULL,
        chave_aleatoria TEXT,
        foto_rosto TEXT,
        foto_documento TEXT,
        agencia TEXT,
        numero_conta TEXT,
        saldo REAL DEFAULT 0.0,
        chave_cpf_ativa INTEGER DEFAULT 1,
        chave_email_ativa INTEGER DEFAULT 0,
        chave_telefone_ativa INTEGER DEFAULT 0
      )
    ''');

    // 2. Tabela legada de transferências
    await db.execute('''
      CREATE TABLE transferencias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_usuario INTEGER,
        recebedor TEXT NOT NULL,
        valor REAL NOT NULL,
        data TEXT NOT NULL,
        tipo TEXT NOT NULL DEFAULT 'SAIDA',
        id_transacao TEXT,
        pagador TEXT,
        cpf_recebedor TEXT,
        agencia_recebedor TEXT,
        conta_recebedor TEXT
      )
    ''');

    // 3. Novas tabelas de Core Banking
    await _createCoreBankingTables(db);
    await _seedSystemAccounts(db);
  }

  Future<void> _createCoreBankingTables(sqflite.DatabaseExecutor db) async {
    // Tabela de Contas Bancárias
    await db.execute('''
      CREATE TABLE IF NOT EXISTS accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        account_number TEXT NOT NULL UNIQUE,
        agency TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'CHECKING',
        created_at TEXT NOT NULL
      )
    ''');

    // Tabela de Transações Financeiras (com restrição de Idempotência UNIQUE)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id TEXT PRIMARY KEY,
        idempotency_key TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        amount_cents INTEGER NOT NULL,
        description TEXT NOT NULL,
        sender_account_id INTEGER,
        receiver_account_id INTEGER,
        sender_name TEXT,
        receiver_name TEXT,
        receiver_cpf TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (sender_account_id) REFERENCES accounts (id),
        FOREIGN KEY (receiver_account_id) REFERENCES accounts (id)
      )
    ''');

    // Tabela de Lançamentos Contábeis do Ledger de Partidas Dobradas (Imutável)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id TEXT NOT NULL,
        account_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount_cents INTEGER NOT NULL,
        signed_amount_cents INTEGER NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id),
        FOREIGN KEY (account_id) REFERENCES accounts (id)
      )
    ''');

    // Tabela de CQRS / Snapshot de Saldo (Cache de alta performance reconciliável)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS account_balances_snapshot (
        account_id INTEGER PRIMARY KEY,
        balance_cents INTEGER NOT NULL DEFAULT 0,
        last_entry_id INTEGER,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts (id)
      )
    ''');

    // Índices de alta performance para o Ledger
    await db.execute('CREATE INDEX IF NOT EXISTS idx_entries_account ON entries (account_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_entries_tx ON entries (transaction_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tx_idempotency ON transactions (idempotency_key);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_accounts_user ON accounts (user_id);');
  }

  Future<void> _seedSystemAccounts(sqflite.DatabaseExecutor db) async {
    final now = DateTime.now().toIso8601String();

    // Conta 1: Caixa / Cofre Central do Banco (Contrapartida de Depósitos Virtuais)
    await db.insert('accounts', {
      'id': systemVaultAccountId,
      'user_id': 0,
      'account_number': 'VAULT-0001',
      'agency': '0000',
      'type': 'SYSTEM_VAULT',
      'created_at': now,
    }, conflictAlgorithm: sqflite.ConflictAlgorithm.ignore);

    await db.insert('account_balances_snapshot', {
      'account_id': systemVaultAccountId,
      'balance_cents': 0,
      'last_entry_id': null,
      'updated_at': now,
    }, conflictAlgorithm: sqflite.ConflictAlgorithm.ignore);

    // Conta 2: Câmara de Compensação Externa (Clearing House)
    await db.insert('accounts', {
      'id': systemClearingAccountId,
      'user_id': 0,
      'account_number': 'CLEAR-0001',
      'agency': '0000',
      'type': 'SYSTEM_CLEARING',
      'created_at': now,
    }, conflictAlgorithm: sqflite.ConflictAlgorithm.ignore);

    await db.insert('account_balances_snapshot', {
      'account_id': systemClearingAccountId,
      'balance_cents': 0,
      'last_entry_id': null,
      'updated_at': now,
    }, conflictAlgorithm: sqflite.ConflictAlgorithm.ignore);
  }

  Future<void> _upgradeDB(sqflite.Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _adicionarColunaSeNaoExistir(
        db,
        'transferencias',
        'tipo',
        "TEXT NOT NULL DEFAULT 'SAIDA'",
      );
    }

    if (oldVersion < 3) {
      await _adicionarColunaSeNaoExistir(
        db,
        'usuarios',
        'senha_transacao',
        'TEXT',
      );
    }

    if (oldVersion < 4) {
      await _adicionarColunaSeNaoExistir(db, 'transferencias', 'id_transacao', 'TEXT');
      await _adicionarColunaSeNaoExistir(db, 'transferencias', 'pagador', 'TEXT');
      await _adicionarColunaSeNaoExistir(db, 'transferencias', 'cpf_recebedor', 'TEXT');
      await _adicionarColunaSeNaoExistir(db, 'transferencias', 'agencia_recebedor', 'TEXT');
      await _adicionarColunaSeNaoExistir(db, 'transferencias', 'conta_recebedor', 'TEXT');
    }

    if (oldVersion < 5) {
      await _createCoreBankingTables(db);
      await _seedSystemAccounts(db);
      await _migrarDadosLegadosParaLedger(db);
    }
  }

  Future<void> _migrarDadosLegadosParaLedger(sqflite.Database db) async {
    final usuarios = await db.query('usuarios');
    final now = DateTime.now().toIso8601String();

    for (final u in usuarios) {
      final userId = u['id'] as int;
      final agencia = (u['agencia'] as String?) ?? '0001';
      final conta = (u['numero_conta'] as String?) ?? '$userId-0';
      final saldoLegado = (u['saldo'] as num?)?.toDouble() ?? 0.0;

      // Cria a conta do cliente se não existir
      final contasExistentes = await db.query(
        'accounts',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      int accountId;
      if (contasExistentes.isEmpty) {
        accountId = await db.insert('accounts', {
          'user_id': userId,
          'account_number': conta,
          'agency': agencia,
          'type': 'CHECKING',
          'created_at': now,
        });
      } else {
        accountId = contasExistentes.first['id'] as int;
      }

      // Migração de saldo legado para o Ledger
      final saldoCents = (saldoLegado * 100).round();
      if (saldoCents > 0) {
        final txId = 'MIGRATION-USER-$userId';
        final idempKey = 'migration_init_$userId';

        await db.insert('transactions', {
          'id': txId,
          'idempotency_key': idempKey,
          'type': 'DEPOSIT',
          'status': 'COMPLETED',
          'amount_cents': saldoCents,
          'description': 'Migração de saldo legado para o Ledger',
          'sender_account_id': systemVaultAccountId,
          'receiver_account_id': accountId,
          'sender_name': 'PayBank Tesouraria',
          'receiver_name': u['nome'],
          'created_at': now,
        }, conflictAlgorithm: sqflite.ConflictAlgorithm.ignore);

        // Débito no cofre do sistema
        await db.insert('entries', {
          'transaction_id': txId,
          'account_id': systemVaultAccountId,
          'type': 'DEBIT',
          'amount_cents': saldoCents,
          'signed_amount_cents': -saldoCents,
          'description': 'Provisão de saldo legado',
          'created_at': now,
        });

        // Crédito na conta do correntista
        final entryId = await db.insert('entries', {
          'transaction_id': txId,
          'account_id': accountId,
          'type': 'CREDIT',
          'amount_cents': saldoCents,
          'signed_amount_cents': saldoCents,
          'description': 'Saldo inicial migrado',
          'created_at': now,
        });

        // Inicializa o snapshot CQRS
        await db.insert('account_balances_snapshot', {
          'account_id': accountId,
          'balance_cents': saldoCents,
          'last_entry_id': entryId,
          'updated_at': now,
        }, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
      } else {
        await db.insert('account_balances_snapshot', {
          'account_id': accountId,
          'balance_cents': 0,
          'last_entry_id': null,
          'updated_at': now,
        }, conflictAlgorithm: sqflite.ConflictAlgorithm.ignore);
      }
    }
  }

  Future<void> _adicionarColunaSeNaoExistir(
    sqflite.Database db,
    String tabela,
    String coluna,
    String definicao,
  ) async {
    final colunas = await db.rawQuery('PRAGMA table_info($tabela)');
    final existe = colunas.any((c) => c['name'] == coluna);

    if (!existe) {
      await db.execute('ALTER TABLE $tabela ADD COLUMN $coluna $definicao');
    }
  }

  // ==========================================
  // OPERAÇÕES DO LEDGER & CQRS SNAPSHOTS
  // ==========================================

  /// Recupera o saldo em centavos através do Snapshot CQRS (leitura ultrarrápida O(1)).
  Future<int> getSnapshotBalanceCents(
    int accountId, [
    sqflite.DatabaseExecutor? executor,
  ]) async {
    final db = executor ?? await database;
    final result = await db.query(
      'account_balances_snapshot',
      columns: ['balance_cents'],
      where: 'account_id = ?',
      whereArgs: [accountId],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['balance_cents'] as int;
    }

    // Se o snapshot ainda não existir, reconcilia a partir do ledger
    return await reconcileAccountBalance(accountId, db);
  }

  /// Calcula o saldo derivado através da soma de todos os lançamentos imutáveis do Ledger.
  Future<int> calculateLedgerBalanceCents(
    int accountId, [
    sqflite.DatabaseExecutor? executor,
  ]) async {
    final db = executor ?? await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(signed_amount_cents), 0) AS balance FROM entries WHERE account_id = ?',
      [accountId],
    );

    return (result.first['balance'] as num?)?.toInt() ?? 0;
  }

  /// Reconcilia o Snapshot com a verdade canônica dos lançamentos contábeis (Entries).
  Future<int> reconcileAccountBalance(
    int accountId, [
    sqflite.DatabaseExecutor? executor,
  ]) async {
    final db = executor ?? await database;
    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(signed_amount_cents), 0) AS total_cents,
        MAX(id) AS last_id
      FROM entries 
      WHERE account_id = ?
    ''', [accountId]);

    final totalCents = (result.first['total_cents'] as num?)?.toInt() ?? 0;
    final lastEntryId = result.first['last_id'] as int?;
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'account_balances_snapshot',
      {
        'account_id': accountId,
        'balance_cents': totalCents,
        'last_entry_id': lastEntryId,
        'updated_at': now,
      },
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );

    return totalCents;
  }

  /// Retorna ou provisiona uma conta bancária vinculada ao usuário.
  Future<int> getOrCreateAccountIdForUser(
    int userId, {
    String? agency,
    String? accountNumber,
    sqflite.DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await database;
    final rows = await db.query(
      'accounts',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (rows.isNotEmpty) {
      return rows.first['id'] as int;
    }

    final now = DateTime.now().toIso8601String();
    final newId = await db.insert('accounts', {
      'user_id': userId,
      'account_number': accountNumber ?? '$userId-0',
      'agency': agency ?? '0001',
      'type': 'CHECKING',
      'created_at': now,
    });

    await db.insert('account_balances_snapshot', {
      'account_id': newId,
      'balance_cents': 0,
      'last_entry_id': null,
      'updated_at': now,
    });

    return newId;
  }

  // ==========================================
  // MÉTODOS DE COMPATIBILIDADE LEGADA
  // ==========================================

  Future<int> gravarUsuario(Map<String, dynamic> row) async {
    final db = await database;
    final userId = await db.insert('usuarios', row);

    final agency = (row['agencia'] as String?) ?? '0001';
    final accountNum = (row['numero_conta'] as String?) ?? '$userId-0';
    final initialBalance = (row['saldo'] as num?)?.toDouble() ?? 0.0;

    final accountId = await getOrCreateAccountIdForUser(
      userId,
      agency: agency,
      accountNumber: accountNum,
      executor: db,
    );

    final initialCents = (initialBalance * 100).round();
    if (initialCents > 0) {
      final now = DateTime.now().toIso8601String();
      final txId = 'INIT-$userId-${DateTime.now().millisecondsSinceEpoch}';

      await db.insert('transactions', {
        'id': txId,
        'idempotency_key': 'init_user_$userId',
        'type': 'DEPOSIT',
        'status': 'COMPLETED',
        'amount_cents': initialCents,
        'description': 'Saldo inicial de abertura de conta',
        'sender_account_id': systemVaultAccountId,
        'receiver_account_id': accountId,
        'created_at': now,
      });

      await db.insert('entries', {
        'transaction_id': txId,
        'account_id': systemVaultAccountId,
        'type': 'DEBIT',
        'amount_cents': initialCents,
        'signed_amount_cents': -initialCents,
        'description': 'Provisão de caixa de abertura',
        'created_at': now,
      });

      final entryId = await db.insert('entries', {
        'transaction_id': txId,
        'account_id': accountId,
        'type': 'CREDIT',
        'amount_cents': initialCents,
        'signed_amount_cents': initialCents,
        'description': 'Crédito de abertura',
        'created_at': now,
      });

      await db.update(
        'account_balances_snapshot',
        {
          'balance_cents': initialCents,
          'last_entry_id': entryId,
          'updated_at': now,
        },
        where: 'account_id = ?',
        whereArgs: [accountId],
      );
    }

    return userId;
  }

  Future<int> atualizarUsuario(int id, Map<String, dynamic> valores) async {
    final db = await database;
    return await db.update(
      'usuarios',
      valores,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> buscarTodosUsuarios() async {
    final db = await database;
    return await db.query('usuarios');
  }

  Future<Map<String, dynamic>?> buscarUsuarioPorLogin(String nomeUsuario) async {
    final db = await database;
    final maps = await db.query(
      'usuarios',
      where: 'nome_usuario = ?',
      whereArgs: [nomeUsuario],
    );

    if (maps.isNotEmpty) {
      final user = Map<String, dynamic>.from(maps.first);
      final userId = user['id'] as int;
      final accountId = await getOrCreateAccountIdForUser(userId, executor: db);
      final balanceCents = await getSnapshotBalanceCents(accountId, db);
      user['saldo'] = balanceCents / 100.0;
      user['account_id'] = accountId;
      return user;
    }

    return null;
  }

  Future<Map<String, dynamic>?> buscarUsuarioPorId(int id) async {
    final db = await database;
    final maps = await db.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final user = Map<String, dynamic>.from(maps.first);
      final accountId = await getOrCreateAccountIdForUser(id, executor: db);
      final balanceCents = await getSnapshotBalanceCents(accountId, db);
      user['saldo'] = balanceCents / 100.0;
      user['account_id'] = accountId;
      return user;
    }

    return null;
  }

  Future<Map<String, dynamic>?> buscarUsuarioPorChavePix({
    required String tipo,
    required String chave,
  }) async {
    final db = await database;

    String where;
    List<dynamic> whereArgs;

    if (tipo == 'CPF') {
      where = 'cpf = ? AND chave_cpf_ativa = 1';
      whereArgs = [chave];
    } else if (tipo == 'Celular') {
      where = 'telefone = ? AND chave_telefone_ativa = 1';
      whereArgs = [chave];
    } else if (tipo == 'E-mail') {
      where = 'email = ? AND chave_email_ativa = 1';
      whereArgs = [chave];
    } else {
      where = 'chave_aleatoria = ?';
      whereArgs = [chave];
    }

    final resultado = await db.query(
      'usuarios',
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );

    if (resultado.isNotEmpty) {
      final user = Map<String, dynamic>.from(resultado.first);
      final userId = user['id'] as int;
      final accountId = await getOrCreateAccountIdForUser(userId, executor: db);
      final balanceCents = await getSnapshotBalanceCents(accountId, db);
      user['saldo'] = balanceCents / 100.0;
      user['account_id'] = accountId;
      return user;
    }

    return null;
  }

  Future<int> gravarTransferencia(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('transferencias', row);
  }

  Future<List<Map<String, dynamic>>> buscarTransferenciasDoUsuario(
    int idUsuario,
  ) async {
    final db = await database;
    return await db.query(
      'transferencias',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
      orderBy: 'id DESC',
    );
  }

  Future close() async {
    final db = await database;
    await db.close();
  }
}