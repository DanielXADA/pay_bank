import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton: Garante que o aplicativo use apenas uma instância do banco de dados
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Getter para obter o banco de dados ativo
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sistema_usuarios.db');
    return _database!;
  }

  // REQUISITO 1: Função para abrir/criar o banco de dados no dispositivo
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Abre o banco e define a versão. Se for a primeira vez, executa o _createDB
    return await openDatabase(
      path, 
      version: 1, 
      onCreate: _createDB
    );
  }

  // REQUISITO 1 (Continuação): Função que cria a tabela quando o app abre pela primeira vez
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        nome_usuario TEXT NOT NULL UNIQUE,
        senha TEXT NOT NULL
      )
    ''');
  }

  // REQUISITO 2 & 3: Função para INSERIR / GRAVAR os dados capturados
  // Esta função recebe os dados em formato de Map (Chave-Valor) e grava no SQLite
  Future<int> gravarUsuario(Map<String, dynamic> row) async {
    final db = await instance.database;
    
    // O método insert cuida da tradução dos dados para a query SQL de forma segura
    return await db.insert('usuarios', row);
  }

  // REQUISITO 4: Função para BUSCAR (ler) os dados gravados no banco
  Future<List<Map<String, dynamic>>> buscarTodosUsuarios() async {
    final db = await instance.database;

    // Retorna uma lista com todos os registros encontrados na tabela
    return await db.query('usuarios');
  }

  // Função extra útil: Buscar um usuário específico pelo 'nome_usuario' (bom para Login)
  Future<Map<String, dynamic>?> buscarUsuarioPorLogin(String nomeUsuario) async {
    final db = await instance.database;

    final maps = await db.query(
      'usuarios',
      where: 'nome_usuario = ?',
      whereArgs: [nomeUsuario],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  // Função para fechar o banco de dados quando necessário
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}