import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/db_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usuarioController = TextEditingController();
  final _senhaController = TextEditingController();

  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _ocultarSenha = true;
  bool _autenticando = false;
  String? _ultimoUsuarioSalvo;

  @override
  void initState() {
    super.initState();
    _carregarUltimoUsuario();
  }

  Future<void> _carregarUltimoUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioSalvo = prefs.getString('ultimo_usuario');

    if (!mounted) return;

    setState(() {
      _ultimoUsuarioSalvo = usuarioSalvo;

      if (usuarioSalvo != null && usuarioSalvo.isNotEmpty) {
        _usuarioController.text = usuarioSalvo;
      }
    });
  }

  Future<void> _salvarUltimoUsuario(String nomeUsuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ultimo_usuario', nomeUsuario);
  }

  Future<void> _fazerLoginNormal() async {
    final nomeUsuario = _usuarioController.text.trim();

    final bancoDados = DatabaseHelper.instance;
    final usuarioBanco = await bancoDados.buscarUsuarioPorLogin(nomeUsuario);

    if (!mounted) return;

    if (usuarioBanco != null && usuarioBanco['senha'] == _senhaController.text) {
      await _salvarUltimoUsuario(usuarioBanco['nome_usuario']);

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/principal',
        arguments: usuarioBanco,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário ou senha incorretos!')),
      );
    }
  }

  Future<void> _entrarComBiometria() async {
    try {
      setState(() {
        _autenticando = true;
      });

      final dispositivoSuporta = await _localAuth.isDeviceSupported();
      final podeVerificar = await _localAuth.canCheckBiometrics;

      if (!dispositivoSuporta && !podeVerificar) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometria ou bloqueio de tela não disponível.'),
          ),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final usuarioSalvo = prefs.getString('ultimo_usuario');

      if (usuarioSalvo == null || usuarioSalvo.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Faça login com usuário e senha pelo menos uma vez.'),
          ),
        );
        return;
      }

      final autenticado = await _localAuth.authenticate(
        localizedReason: 'Confirme sua identidade para entrar no Pay Bank',
      );

      if (!autenticado) return;

      final bancoDados = DatabaseHelper.instance;
      final usuarioBanco = await bancoDados.buscarUsuarioPorLogin(usuarioSalvo);

      if (!mounted) return;

      if (usuarioBanco == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário salvo não encontrado.')),
        );
        return;
      }

      Navigator.pushReplacementNamed(
        context,
        '/principal',
        arguments: usuarioBanco,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na autenticação: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _autenticando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final podeUsarBiometria =
        _ultimoUsuarioSalvo != null && _ultimoUsuarioSalvo!.isNotEmpty;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance,
              size: 80,
              color: Colors.green,
            ),

            const Text(
              'Pay Bank',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            TextField(
              controller: _usuarioController,
              decoration: const InputDecoration(
                labelText: 'Usuário',
              ),
            ),

            TextField(
              controller: _senhaController,
              obscureText: _ocultarSenha,
              decoration: InputDecoration(
                labelText: 'Senha',
                suffixIcon: IconButton(
                  icon: Icon(
                    _ocultarSenha ? Icons.visibility : Icons.visibility_off,
                  ),
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
              onPressed: _fazerLoginNormal,
              child: const Text('Entrar'),
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: _autenticando ? null : _entrarComBiometria,
              icon: const Icon(Icons.fingerprint),
              label: Text(
                _autenticando ? 'Autenticando...' : 'Entrar com biometria',
              ),
            ),

            if (!podeUsarBiometria)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Faça login uma vez para ativar a biometria.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/cadastro'),
              child: const Text('Não tem conta? Cadastre-se aqui'),
            ),
          ],
        ),
      ),
    );
  }
}