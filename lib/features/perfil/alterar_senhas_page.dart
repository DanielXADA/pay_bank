import 'package:flutter/material.dart';
import '../../database/db_helper.dart';

class AlterarSenhasPage extends StatefulWidget {
  const AlterarSenhasPage({super.key});

  @override
  State<AlterarSenhasPage> createState() => _AlterarSenhasPageState();
}

class _AlterarSenhasPageState extends State<AlterarSenhasPage> {
  final Color greenPrimary = const Color(0xFF1DB954);
  final Color greenDark = const Color(0xFF191414);
  final Color greyText = const Color(0xFF6C757D);

  Map<String, dynamic> _usuarioDados = {};
  bool _inicializado = false;

  final _controladorSenha6 = TextEditingController();
  final _controladorSenha8 = TextEditingController();

  bool _ocultarSenha6 = true;
  bool _ocultarSenha8 = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inicializado) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _usuarioDados = Map<String, dynamic>.from(args);
      }
      _inicializado = true;
    }
  }

  Future<void> _salvarSenha6() async {
    if (_controladorSenha6.text.trim().length != 6) {
      _mostrarMensagem('A senha de transição deve ter exatamente 6 números.');
      return;
    }

    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    await db.update(
      'usuarios',
      {'senha_transacao': _controladorSenha6.text.trim()},
      where: 'id = ?',
      whereArgs: [_usuarioDados['id']],
    );

    _mostrarMensagem('Senha de 6 dígitos alterada com sucesso!');
    _controladorSenha6.clear();
  }

  Future<void> _salvarSenha8() async {
    if (_controladorSenha8.text.trim().length < 8) {
      _mostrarMensagem('A senha de acesso deve ter no mínimo 8 dígitos.');
      return;
    }

    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    await db.update(
      'usuarios',
      {'senha': _controladorSenha8.text.trim()},
      where: 'id = ?',
      whereArgs: [_usuarioDados['id']],
    );

    _mostrarMensagem('Senha de acesso alterada com sucesso!');
    _controladorSenha8.clear();
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Segurança', style: TextStyle(color: greenDark, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: greenDark), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Senha de Transações (6 dígitos)', style: TextStyle(color: greenDark, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Usada para confirmar PIX, transferências e alterações cadastrais.', style: TextStyle(color: greyText, fontSize: 14)),
            const SizedBox(height: 15),
            TextField(
              controller: _controladorSenha6,
              obscureText: _ocultarSenha6,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Nova senha de 6 números',
                labelStyle: TextStyle(color: greyText),
                suffixIcon: IconButton(
                  icon: Icon(_ocultarSenha6 ? Icons.visibility_off : Icons.visibility, color: greyText),
                  onPressed: () => setState(() => _ocultarSenha6 = !_ocultarSenha6),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _salvarSenha6,
                style: ElevatedButton.styleFrom(backgroundColor: greenDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Atualizar Senha de 6 Dígitos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
            Text('Senha de Acesso (8 dígitos)', style: TextStyle(color: greenDark, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Usada para entrar no aplicativo e recuperar a conta.', style: TextStyle(color: greyText, fontSize: 14)),
            const SizedBox(height: 15),
            TextField(
              controller: _controladorSenha8,
              obscureText: _ocultarSenha8,
              maxLength: 16,
              decoration: InputDecoration(
                labelText: 'Nova senha de acesso',
                labelStyle: TextStyle(color: greyText),
                suffixIcon: IconButton(
                  icon: Icon(_ocultarSenha8 ? Icons.visibility_off : Icons.visibility, color: greyText),
                  onPressed: () => setState(() => _ocultarSenha8 = !_ocultarSenha8),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _salvarSenha8,
                style: ElevatedButton.styleFrom(backgroundColor: greenPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Atualizar Senha de Acesso', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}