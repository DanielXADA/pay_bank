import 'package:flutter/material.dart';
import '../../database/db_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userController = TextEditingController();
  final _senhaController = TextEditingController();

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
            TextField(controller: _userController, decoration: const InputDecoration(labelText: 'Usuário')),
            TextField(controller: _senhaController, decoration: const InputDecoration(labelText: 'Senha'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final db = DatabaseHelper.instance;
                // Busca o usuário no banco do Rian
                final user = await db.buscarUsuarioPorLogin(_userController.text);

                if (user != null && user['senha'] == _senhaController.text) {
                  Navigator.pushReplacementNamed(context, '/principal');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuário ou senha incorretos!')));
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