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
        // Atualizado para o verde oficial do banco
        primaryColor: const Color(0xFF1DB954),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1DB954)),
      ),
      initialRoute: '/',
      routes: {
        // Removido o "const" das páginas para evitar erro caso algum arquivo não tenha suporte
        '/': (context) => WelcomePage(),
        '/login': (context) => LoginPage(),
        '/cadastro': (context) => CadastroPage(),
        '/principal': (context) => PrincipalPage(),
        '/cotacao': (context) => CotacaoPage(),
        '/transferencia': (context) => TransferenciaPage(),
        '/perfil': (context) => PerfilPage(),
        '/meus_dados': (context) => MeusDadosPage(),
        '/minhas_chaves': (context) => MinhasChavesPage(),
      },
    );
  }
}