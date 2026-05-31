import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../database/db_helper.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final Color greenPrimary = const Color(0xFF1DB954);
  final Color greenDark = const Color(0xFF191414);
  final Color greyBackground = const Color(0xFFF8F9FA);
  final Color greyText = const Color(0xFF6C757D);

  Map<String, dynamic> _usuarioDados = {};
  bool _inicializado = false;

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

  Future<void> _carregarDadosBD() async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    
    final maps = await db.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [_usuarioDados['id']],
    );

    if (maps.isNotEmpty && mounted) {
      setState(() {
        _usuarioDados = Map<String, dynamic>.from(maps.first);
      });
    }
  }

  Future<void> _capturarImagem(ImageSource origem) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: origem);
    
    if (image != null && _usuarioDados['id'] != null) {
      setState(() {
        _usuarioDados['foto_rosto'] = image.path;
      });
      
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;
      await db.update(
        'usuarios', 
        {'foto_rosto': image.path}, 
        where: 'id = ?', 
        whereArgs: [_usuarioDados['id']]
      );
    }
  }

  Future<void> _removerFoto() async {
    if (_usuarioDados['id'] != null) {
      setState(() {
        _usuarioDados['foto_rosto'] = '';
      });
      
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;
      await db.update(
        'usuarios', 
        {'foto_rosto': ''}, 
        where: 'id = ?', 
        whereArgs: [_usuarioDados['id']]
      );
    }
  }

  void _selecionarFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final temFoto = _usuarioDados['foto_rosto'] != null && _usuarioDados['foto_rosto'].toString().isNotEmpty;
        
        return SafeArea(
          child: Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Foto de Perfil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: greenPrimary),
                title: const Text('Tirar Foto (Câmera)'),
                onTap: () {
                  Navigator.pop(context);
                  _capturarImagem(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: greenPrimary),
                title: const Text('Escolher da Galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _capturarImagem(ImageSource.gallery);
                },
              ),
              if (temFoto)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remover Foto Atual', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _removerFoto();
                  },
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final caminhoFoto = _usuarioDados['foto_rosto'];
    final nome = _usuarioDados['nome'] ?? 'Usuário';
    final email = _usuarioDados['email'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Meu Perfil', style: TextStyle(color: greenDark, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: greenDark), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _selecionarFoto,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        _buildAvatar(caminhoFoto),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: greenPrimary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(nome, style: TextStyle(color: greenDark, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(email, style: TextStyle(color: greyText, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildMenuItem(context, Icons.person_outline, 'Meus Dados', '/meus_dados', _usuarioDados),
            _buildMenuItem(context, Icons.vpn_key_outlined, 'Minhas Chaves PIX', '/minhas_chaves', _usuarioDados),
            _buildMenuItem(context, Icons.security_outlined, 'Segurança e Senhas', '/alterar_senhas', _usuarioDados),
            const SizedBox(height: 20),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(dynamic caminhoFoto) {
    if (caminhoFoto != null && caminhoFoto.toString().isNotEmpty) {
      final arquivo = File(caminhoFoto);
      if (arquivo.existsSync()) {
        return CircleAvatar(radius: 50, backgroundImage: FileImage(arquivo));
      }
    }
    return CircleAvatar(radius: 50, backgroundColor: greyBackground, child: Icon(Icons.person, color: greenPrimary, size: 50));
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String? route, Map<String, dynamic>? args) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: greyBackground, width: 2)),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: greenPrimary.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: greenPrimary)),
        title: Text(title, style: TextStyle(color: greenDark, fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.arrow_forward_ios, color: greyText, size: 16),
        onTap: () async {
          if (route != null) {
            await Navigator.pushNamed(context, route, arguments: _usuarioDados);
            await _carregarDadosBD();
          }
        },
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.red.withValues(alpha: 0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        child: const Text('Sair da Conta', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}