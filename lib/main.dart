import 'package:flutter/material.dart';

import 'features/login/login_page.dart';
import 'features/login/cadastro_page.dart';
import 'features/principal/principal_page.dart';
import 'features/cotacao/cotacao_page.dart';
import 'features/transferencia/transferencia_page.dart';

void main() {
  runApp(const PayBankApp());
}

class PayBankApp extends StatelessWidget {
  const PayBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pay Bank',
      theme: ThemeData(
        primarySwatch: Colors.green, // cor padrao do banco
      ),
      initialRoute: '/login', // abre a tela de login primeiro
      routes: {
        '/login': (context) => const LoginPage(),
        '/cadastro': (context) => const CadastroPage(),
        '/principal': (context) => const PrincipalPage(),
        '/cotacao': (context) => const CotacaoPage(),
        '/transferencia': (context) => const TransferenciaPage(),
      },
    );
  }
}