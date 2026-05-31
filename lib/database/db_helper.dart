import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sistema_usuarios.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
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
        saldo REAL,
        chave_cpf_ativa INTEGER DEFAULT 1,
        chave_email_ativa INTEGER DEFAULT 0,
        chave_telefone_ativa INTEGER DEFAULT 0
      )
    ''');

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
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
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
      await _adicionarColunaSeNaoExistir(
        db,
        'transferencias',
        'id_transacao',
        'TEXT',
      );

      await _adicionarColunaSeNaoExistir(
        db,
        'transferencias',
        'pagador',
        'TEXT',
      );

      await _adicionarColunaSeNaoExistir(
        db,
        'transferencias',
        'cpf_recebedor',
        'TEXT',
      );

      await _adicionarColunaSeNaoExistir(
        db,
        'transferencias',
        'agencia_recebedor',
        'TEXT',
      );

      await _adicionarColunaSeNaoExistir(
        db,
        'transferencias',
        'conta_recebedor',
        'TEXT',
      );
    }
  }

  Future<void> _adicionarColunaSeNaoExistir(
    Database db,
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

  Future<int> gravarUsuario(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('usuarios', row);
  }

  Future<int> atualizarUsuario(int id, Map<String, dynamic> valores) async {
    final db = await instance.database;
    return await db.update(
      'usuarios',
      valores,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> buscarTodosUsuarios() async {
    final db = await instance.database;
    return await db.query('usuarios');
  }

  Future<Map<String, dynamic>?> buscarUsuarioPorLogin(String nomeUsuario) async {
    final db = await instance.database;

    final maps = await db.query(
      'usuarios',
      where: 'nome_usuario = ?',
      whereArgs: [nomeUsuario],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }

    return null;
  }

  Future<Map<String, dynamic>?> buscarUsuarioPorId(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }

    return null;
  }

  Future<Map<String, dynamic>?> buscarUsuarioPorChavePix({
    required String tipo,
    required String chave,
  }) async {
    final db = await instance.database;

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
      return resultado.first;
    }

    return null;
  }

  Future<int> gravarTransferencia(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('transferencias', row);
  }

  Future<List<Map<String, dynamic>>> buscarTransferenciasDoUsuario(
    int idUsuario,
  ) async {
    final db = await instance.database;

    return await db.query(
      'transferencias',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
      orderBy: 'id DESC',
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}