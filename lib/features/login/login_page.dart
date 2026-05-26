import 'package:flutter/material.dart';
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
                // O botão do olhinho
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final bancoDados = DatabaseHelper.instance;
                final usuarioBanco = await bancoDados.buscarUsuarioPorLogin(_usuarioController.text);

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