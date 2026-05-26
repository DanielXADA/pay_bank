import 'package:flutter/material.dart';
import '../../database/db_helper.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  Map<String, dynamic>? _usuarioDados;
  bool _carregando = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_usuarioDados == null) {
      final dadosIniciais = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
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
          const Center(
            child: Icon(Icons.account_circle, size: 80, color: Colors.green),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              _usuarioDados!['nome'],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
              Navigator.pushNamed(context, '/meus_dados', arguments: _usuarioDados).then((_) {
                _carregarDadosBD(_usuarioDados!['nome_usuario']);
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.pix_outlined),
            title: const Text('Minhas chaves Pix'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, '/minhas_chaves', arguments: _usuarioDados).then((_) {
                _carregarDadosBD(_usuarioDados!['nome_usuario']);
              });
            },
          ),
        ],
      ),
    );
  }
}