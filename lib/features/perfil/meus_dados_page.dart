import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    _usuarioDados ??= ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
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
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                  
                  if (!mounted) return;

                  setState(() {
                    _usuarioDados = atualizado;
                  });
                  
                  _controladorEdicao.clear();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label updated!')));
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoAlterarSenha() {
    final controladorNovaSenha = TextEditingController();
    final controladorConfirmarNovaSenha = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Alterar Senha'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controladorNovaSenha,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Nova Senha (mínimo 6 números)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controladorConfirmarNovaSenha,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Confirmar Nova Senha',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nova = controladorNovaSenha.text.trim();
                final confirma = controladorConfirmarNovaSenha.text.trim();

                if (nova.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('A senha deve ter pelo menos 6 números!')),
                  );
                  return;
                }

                if (nova != confirma) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('As senhas não são iguais!')),
                  );
                  return;
                }

                final bancoDados = DatabaseHelper.instance;
                await bancoDados.atualizarUsuario(_usuarioDados!['id'], {'senha': nova});
                
                final atualizado = await bancoDados.buscarUsuarioPorLogin(_usuarioDados!['nome_usuario']);

                if (!mounted) return;

                setState(() {
                  _usuarioDados = atualizado;
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Senha atualizada com sucesso!')),
                );
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
            const Divider(),
            ListTile(
              title: const Text('Senha de Acesso'),
              subtitle: const Text('********'),
              trailing: _dadosRevelados
                  ? IconButton(
                      icon: const Icon(Icons.edit, color: Colors.green),
                      onPressed: _mostrarDialogoAlterarSenha,
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