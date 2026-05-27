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
  Map<String, dynamic>? _usuarioDados;
  bool _carregando = true;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_usuarioDados == null) {
      final dadosIniciais =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (dadosIniciais != null) {
        _carregarDadosBD(dadosIniciais['nome_usuario']);
      }
    }
  }

  Future<void> _carregarDadosBD(String nomeUsuario) async {
    final bd = DatabaseHelper.instance;
    final dadosAtualizados = await bd.buscarUsuarioPorLogin(nomeUsuario);

    if (dadosAtualizados != null && mounted) {
      setState(() {
        _usuarioDados = dadosAtualizados;
        _carregando = false;
      });
    }
  }

  Future<void> _selecionarFoto(ImageSource origem) async {
    if (_usuarioDados == null) return;

    final XFile? imagem = await _imagePicker.pickImage(
      source: origem,
      imageQuality: 70,
    );

    if (imagem == null) return;

    final bd = DatabaseHelper.instance;

    await bd.atualizarUsuario(
      _usuarioDados!['id'],
      {
        'foto_rosto': imagem.path,
      },
    );

    await _carregarDadosBD(_usuarioDados!['nome_usuario']);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Foto de perfil atualizada!')),
    );
  }

  Future<void> _removerFoto() async {
    if (_usuarioDados == null) return;

    final bd = DatabaseHelper.instance;

    await bd.atualizarUsuario(
      _usuarioDados!['id'],
      {
        'foto_rosto': null,
      },
    );

    await _carregarDadosBD(_usuarioDados!['nome_usuario']);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Foto de perfil removida!')),
    );
  }

  void _mostrarOpcoesFoto() {
    final caminhoFoto = _usuarioDados?['foto_rosto'];
    final temFoto = caminhoFoto != null && caminhoFoto.toString().isNotEmpty;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tirar foto com a câmera'),
                onTap: () {
                  Navigator.pop(context);
                  _selecionarFoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Escolher da galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _selecionarFoto(ImageSource.gallery);
                },
              ),
              if (temFoto)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remover foto'),
                  onTap: () {
                    Navigator.pop(context);
                    _removerFoto();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _fotoPerfil() {
    final caminhoFoto = _usuarioDados?['foto_rosto'];

    if (caminhoFoto != null && caminhoFoto.toString().isNotEmpty) {
      final arquivo = File(caminhoFoto);

      if (arquivo.existsSync()) {
        return CircleAvatar(
          radius: 50,
          backgroundImage: FileImage(arquivo),
        );
      }
    }

    return const CircleAvatar(
      radius: 50,
      backgroundColor: Colors.green,
      child: Icon(
        Icons.account_circle,
        size: 80,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando || _usuarioDados == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Column(
        children: [
          const SizedBox(height: 20),

          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                _fotoPerfil(),
                CircleAvatar(
                  backgroundColor: Colors.green,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    onPressed: _mostrarOpcoesFoto,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Center(
            child: Text(
              _usuarioDados!['nome'],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Center(
            child: Text(
              'Agência: ${_usuarioDados!['agencia']} | Conta: ${_usuarioDados!['numero_conta']}',
              style: const TextStyle(color: Colors.black54),
            ),
          ),

          const SizedBox(height: 30),

          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Meus Dados'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/meus_dados',
                arguments: _usuarioDados,
              ).then((_) {
                _carregarDadosBD(_usuarioDados!['nome_usuario']);
              });
            },
          ),

          ListTile(
            leading: const Icon(Icons.pix_outlined),
            title: const Text('Minhas chaves Pix'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/minhas_chaves',
                arguments: _usuarioDados,
              ).then((_) {
                _carregarDadosBD(_usuarioDados!['nome_usuario']);
              });
            },
          ),
        ],
      ),
    );
  }
}