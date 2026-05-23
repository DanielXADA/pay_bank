import 'package:flutter/material.dart';
import '../../database/db_helper.dart'; // puxando o banco do rian

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userController = TextEditingController();
  final senhaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('pay bank - acesso')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: userController,
              decoration: const InputDecoration(labelText: 'nome de usuario'),
            ),
            TextField(
              controller: senhaController,
              decoration: const InputDecoration(labelText: 'senha'),
              obscureText: true, // esconde a senha
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // gravando no banco de dados de verdade!
                final db = DatabaseHelper.instance;
                await db.gravarUsuario({
                  'nome': 'cliente teste',
                  'nome_usuario': userController.text,
                  'senha': senhaController.text,
                });
                
                print('salvo! usuario: ${userController.text}');
                
                // joga o usuario pra tela principal depois de salvar
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/principal');
                }
              },
              child: const Text('cadastrar e entrar'),
            )
          ],
        ),
      ),
    );
  }
}