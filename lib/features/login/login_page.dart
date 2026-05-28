import 'package:flutter/material.dart';
import 'package:pay_bank/widgets/bouncing_button.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../database/db_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late final AnimationController _controller1;
  late final AnimationController _controller2;

  final _usuarioController = TextEditingController();
  final _senhaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _usuarioController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> bankPalette = [
      const Color(0xFF10251B),
      const Color(0xFF244A3A),
      const Color(0xFF3FA168),
      const Color(0xFFD4F85A),
      const Color(0xFF3FA168),
      const Color(0xFF244A3A),
      const Color(0xFF10251B),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: RotationTransition(
              turns: _controller1,
              child: Transform.scale(
                scale: 2.5,
                child: Opacity(
                  opacity: 0.8,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(colors: bankPalette),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller2,
              builder: (context, child) {
                return Transform.rotate(
                  angle: -_controller2.value * 2 * math.pi,
                  child: child,
                );
              },
              child: Transform.scale(
                scale: 2.0,
                child: Opacity(
                  opacity: 0.6,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: bankPalette.reversed.toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.transparent),
            ),
          ),
          SafeArea(
            child: Center(
              child: _buildFormCard(
                context,
                title: "Entrar",
                children: [
                  _buildInput("Nome de Usuário (@)", _usuarioController),
                  const SizedBox(height: 20),
                  _buildInput("Senha", _senhaController, obscureText: true, keyboardType: TextInputType.number),
                  const SizedBox(height: 30),
                  BouncingButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4F85A),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      final username = _usuarioController.text.trim();
                      final senha = _senhaController.text.trim();

                      if (username.isEmpty || senha.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Por favor, preencha todos os campos!')),
                        );
                        return;
                      }

                      final bancoDados = DatabaseHelper.instance;
                      final usuarioBanco = await bancoDados.buscarUsuarioPorLogin(username);

                      if (!mounted) return;

                      if (usuarioBanco != null && usuarioBanco['senha'] == senha) {
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
                    },
                    child: const Text(
                      "Entrar",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, {required String title, required List<Widget> children}) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFD3D3D3),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF32325D).withOpacity(0.25),
            blurRadius: 50,
            offset: const Offset(0, 30),
            blurStyle: BlurStyle.inner,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 26,
            offset: const Offset(0, 18),
            blurStyle: BlurStyle.inner,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 30),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, {bool obscureText = false, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFF212121), fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF757575)),
        floatingLabelStyle: const TextStyle(color: Color(0xFF3FA168)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF9E9E9E), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF3FA168), width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}