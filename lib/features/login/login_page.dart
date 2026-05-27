import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../database/db_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usuarioController = TextEditingController();
  final _senhaController = TextEditingController();
  
  bool _ocultarSenha = true; 

  void _mostrarDialogoEsqueciSenha() {
    final controladorUser = TextEditingController();
    final controladorCpf = TextEditingController();
    final controladorNascimento = TextEditingController();

    var cpfMask = MaskTextInputFormatter(mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});
    var dataMask = MaskTextInputFormatter(mask: '##/##/####', filter: {"#": RegExp(r'[0-9]')});

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Recuperar Senha'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controladorUser,
                  decoration: const InputDecoration(
                    labelText: 'Nome de Usuário (@)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controladorCpf,
                  inputFormatters: [cpfMask],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Confirme seu CPF',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controladorNascimento,
                  inputFormatters: [dataMask],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Data de Nascimento',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final username = controladorUser.text.trim();
                final cpf = controladorCpf.text.trim();
                final nascimento = controladorNascimento.text.trim();

                if (username.isEmpty || cpf.isEmpty || nascimento.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preencha todos os campos!')),
                  );
                  return;
                }

                final bancoDados = DatabaseHelper.instance;
                final usuario = await bancoDados.buscarUsuarioPorLogin(username);

                if (usuario != null && 
                    usuario['cpf'] == cpf && 
                    usuario['data_nascimento'] == nascimento) {
                  
                  if (!mounted) return;
                  Navigator.pop(context);
                  _mostrarDialogoNovaSenha(usuario['id']);
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dados incorretos ou usuário não encontrado!')),
                  );
                }
              },
              child: const Text('Verificar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoNovaSenha(int idUsuario) {
    final controladorNova = TextEditingController();
    final controladorConfirma = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Criar Nova Senha'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controladorNova,
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
                controller: controladorConfirma,
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
            ElevatedButton(
              onPressed: () async {
                final nova = controladorNova.text.trim();
                final confirma = controladorConfirma.text.trim();

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
                await bancoDados.atualizarUsuario(idUsuario, {'senha': nova});

                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Senha redefinida com sucesso!')),
                );
              },
              child: const Text('Redefinir Senha'),
                ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance, size: 80, color: Colors.green),
            const Text('Pay Bank', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            TextField(
              controller: _usuarioController, 
              decoration: const InputDecoration(labelText: 'Usuário')
            ),
            TextField(
              controller: _senhaController, 
              obscureText: _ocultarSenha,
              decoration: InputDecoration(
                labelText: 'Senha',
                suffixIcon: IconButton(
                  icon: Icon(_ocultarSenha ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _ocultarSenha = !_ocultarSenha;
                    });
                  },
                ),
              ), 
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _mostrarDialogoEsqueciSenha,
                child: const Text('Esqueceu sua senha?', style: TextStyle(color: Colors.grey)),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final bancoDados = DatabaseHelper.instance;
                final usuarioBanco = await bancoDados.buscarUsuarioPorLogin(_usuarioController.text);

                if (!mounted) return;

                if (usuarioBanco != null && usuarioBanco['senha'] == _senhaController.text) {
                  Navigator.pushReplacementNamed(
                    context, 
                    '/principal',
                    arguments: usuarioBanco,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Usuário ou senha incorretos!'))
                  );
                }
              },
              child: const Text('Entrar'),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/cadastro'),
              child: const Text('Não tem conta? Cadastre-se aqui'),
            )
          ],
        ),
      ),
    );
  }
}