import 'package:flutter/material.dart';
import 'pages/welcome_page.dart';
import 'features/login/login_page.dart';
import 'features/login/cadastro_page.dart';
import 'features/principal/principal_page.dart';
import 'features/cotacao/cotacao_page.dart';
import 'features/transferencia/transferencia_page.dart';
import 'features/perfil/perfil_page.dart';
import 'features/perfil/meus_dados_page.dart';
import 'features/perfil/minhas_chaves_page.dart';

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
        primarySwatch: Colors.green,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/cadastro': (context) => const CadastroPage(),
        '/principal': (context) => const PrincipalPage(),
        '/cotacao': (context) => const CotacaoPage(),
        '/transferencia': (context) => const TransferenciaPage(),
        '/perfil': (context) => const PerfilPage(),
        '/meus_dados': (context) => const MeusDadosPage(),
        '/minhas_chaves': (context) => const MinhasChavesPage(),
      },
    );
  }
}