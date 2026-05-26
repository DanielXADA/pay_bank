import 'package:flutter/material.dart';
import 'dart:math';
import '../../database/db_helper.dart';

class MinhasChavesPage extends StatefulWidget {
  const MinhasChavesPage({super.key});

  @override
  State<MinhasChavesPage> createState() => _MinhasChavesPageState();
}

class _MinhasChavesPageState extends State<MinhasChavesPage> {
  Map<String, dynamic>? _usuarioDados;
  bool _carregando = true;
  final _controladorSenha = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_usuarioDados == null) {
      final dadosIniciais = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (dadosIniciais != null) {
        _carregarDadosAtualizados(dadosIniciais['nome_usuario']);
      }
    }
  }

  Future<void> _carregarDadosAtualizados(String nomeUsuario) async {
    final bancoDados = DatabaseHelper.instance;
    final dadosNovos = await bancoDados.buscarUsuarioPorLogin(nomeUsuario);
    if (mounted) {
      setState(() {
        _usuarioDados = dadosNovos;
        _carregando = false;
      });
    }
  }

  String _criarTextoChaveAleatoria() {
    const caracteres = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final randomico = Random();
    return String.fromCharCodes(Iterable.generate(
      20, (_) => caracteres.codeUnitAt(randomico.nextInt(caracteres.length))
    ));
  }

  void _solicitarSenhaParaChave(String coluna, dynamic valorAtivacao) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Senha'),
          content: TextField(
            controller: _controladorSenha,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Digite sua senha de acesso',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _controladorSenha.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_controladorSenha.text == _usuarioDados!['senha']) {
                  Navigator.pop(context);
                  final bancoDados = DatabaseHelper.instance;
                  
                  Map<String, dynamic> valoresParaAtualizar = {coluna: valorAtivacao};
                  if (coluna == 'chave_aleatoria' && valorAtivacao != null) {
                    valoresParaAtualizar = {'chave_aleatoria': _criarTextoChaveAleatoria()};
                  }

                  await bancoDados.atualizarUsuario(_usuarioDados!['id'], valoresParaAtualizar);
                  _carregarDadosAtualizados(_usuarioDados!['nome_usuario']);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Operação realizada com sucesso!')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Senha incorreta!')));
                }
                _controladorSenha.clear();
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando || _usuarioDados == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final cpfAtivo = _usuarioDados!['chave_cpf_ativa'] == 1;
    final emailAtivo = _usuarioDados!['chave_email_ativa'] == 1;
    final telefoneAtivo = _usuarioDados!['chave_telefone_ativa'] == 1;
    final temChaveAleatoria = _usuarioDados!['chave_aleatoria'] != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Chaves PIX')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Suas chaves cadastradas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            ListTile(
              leading: const Icon(Icons.badge, color: Colors.green),
              title: const Text('CPF'),
              subtitle: Text(_usuarioDados!['cpf']),
              trailing: cpfAtivo
                  ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _solicitarSenhaParaChave('chave_cpf_ativa', 0),
                    )
                  : ElevatedButton(
                      onPressed: () => _solicitarSenhaParaChave('chave_cpf_ativa', 1),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text('Criar'),
                    ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.shuffle, color: Colors.green),
              title: const Text('Chave Aleatória'),
              subtitle: Text(temChaveAleatoria ? _usuarioDados!['chave_aleatoria'] : 'Nenhuma chave cadastrada'),
              trailing: temChaveAleatoria
                  ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _solicitarSenhaParaChave('chave_aleatoria', null),
                    )
                  : ElevatedButton(
                      onPressed: () => _solicitarSenhaParaChave('chave_aleatoria', true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text('Criar'),
                    ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.green),
              title: const Text('E-mail'),
              subtitle: Text(_usuarioDados!['email']),
              trailing: emailAtivo
                  ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _solicitarSenhaParaChave('chave_email_ativa', 0),
                    )
                  : ElevatedButton(
                      onPressed: () => _solicitarSenhaParaChave('chave_email_ativa', 1),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text('Criar'),
                    ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.smartphone, color: Colors.green),
              title: const Text('Telefone'),
              subtitle: Text(_usuarioDados!['telefone']),
              trailing: telefoneAtivo
                  ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _solicitarSenhaParaChave('chave_telefone_ativa', 0),
                    )
                  : ElevatedButton(
                      onPressed: () => _solicitarSenhaParaChave('chave_telefone_ativa', 1),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text('Criar'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}