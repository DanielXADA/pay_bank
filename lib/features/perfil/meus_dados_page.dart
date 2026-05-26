import 'package:flutter/material.dart';
import '../../database/db_helper.dart';

class MeusDadosPage extends StatefulWidget {
  const MeusDadosPage({super.key});

  @override
  State<MeusDadosPage> createState() => _MeusDadosPageState();
}

class _MeusDadosPageState extends State<MeusDadosPage> {
  bool _dadosRevelados = false;
  Map<String, dynamic>? _usuarioDados;
  final _controladorSenha = TextEditingController();
  final _controladorEdicao = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_usuarioDados == null) {
      _usuarioDados = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    }
  }

  void _verificarSenhaParaRevelar(Map<String, dynamic> dados) {
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
              onPressed: () {
                if (_controladorSenha.text == dados['senha']) {
                  setState(() {
                    _dadosRevelados = true;
                  });
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Senha incorreta!')),
                  );
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

  void _mostrarDialogoEdicao(String coluna, String label, String valorAtual) {
    _controladorEdicao.text = valorAtual;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Alterar $label'),
          content: TextField(
            controller: _controladorEdicao,
            decoration: InputDecoration(
              labelText: 'Novo $label',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _controladorEdicao.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final novoValor = _controladorEdicao.text.trim();
                if (novoValor.isNotEmpty) {
                  final bancoDados = DatabaseHelper.instance;
                  await bancoDados.atualizarUsuario(_usuarioDados!['id'], {coluna: novoValor});
                  
                  final atualizado = await bancoDados.buscarUsuarioPorLogin(_usuarioDados!['nome_usuario']);
                  setState(() {
                    _usuarioDados = atualizado;
                  });
                  
                  _controladorEdicao.clear();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label atualizado!')));
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_usuarioDados == null) {
      return const Scaffold(
        body: Center(child: Text('Erro ao carregar dados.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Meus Dados')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: const Text('Nome Completo'),
              subtitle: Text(_usuarioDados!['nome']),
            ),
            const Divider(),
            ListTile(
              title: const Text('CPF'),
              subtitle: Text(_dadosRevelados ? _usuarioDados!['cpf'] : '***.***.***-**'),
            ),
            const Divider(),
            ListTile(
              title: const Text('E-mail'),
              subtitle: Text(_dadosRevelados ? _usuarioDados!['email'] : '******@***.com'),
              trailing: _dadosRevelados
                  ? IconButton(
                      icon: const Icon(Icons.edit, color: Colors.green),
                      onPressed: () => _mostrarDialogoEdicao('email', 'E-mail', _usuarioDados!['email']),
                    )
                  : null,
            ),
            const Divider(),
            ListTile(
              title: const Text('Telefone'),
              subtitle: Text(_dadosRevelados ? _usuarioDados!['telefone'] : '(**) *****-****'),
              trailing: _dadosRevelados
                  ? IconButton(
                      icon: const Icon(Icons.edit, color: Colors.green),
                      onPressed: () => _mostrarDialogoEdicao('telefone', 'Telefone', _usuarioDados!['telefone']),
                    )
                  : null,
            ),
            const Divider(),
            ListTile(
              title: const Text('Endereço'),
              subtitle: Text(_dadosRevelados ? _usuarioDados!['endereco'] : '*******************'),
              trailing: _dadosRevelados
                  ? IconButton(
                      icon: const Icon(Icons.edit, color: Colors.green),
                      onPressed: () => _mostrarDialogoEdicao('endereco', 'Endereço', _usuarioDados!['endereco']),
                    )
                  : null,
            ),
            const Spacer(),
            if (!_dadosRevelados)
              ElevatedButton.icon(
                onPressed: () => _verificarSenhaParaRevelar(_usuarioDados!),
                icon: const Icon(Icons.lock_open),
                label: const Text('Revelar Dados Pessoais'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}