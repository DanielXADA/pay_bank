import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:pay_bank/widgets/bouncing_button.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../database/db_helper.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> with TickerProviderStateMixin {
  late final AnimationController _controller1;
  late final AnimationController _controller2;

  final _nomeController = TextEditingController();
  final _userController = TextEditingController();
  final _cpfController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  var cpfMask = MaskTextInputFormatter(mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});
  var foneMask = MaskTextInputFormatter(mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});

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
    _nomeController.dispose();
    _userController.dispose();
    _cpfController.dispose();
    _enderecoController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: _buildFormCard(
                  context,
                  title: "Criar Conta",
                  children: [
                    _buildInput("Nome Completo", _nomeController),
                    const SizedBox(height: 16),
                    _buildInput("Nome de Usuário (@)", _userController),
                    const SizedBox(height: 16),
                    _buildInput("CPF", _cpfController, keyboardType: TextInputType.number, inputFormatters: [cpfMask]),
                    const SizedBox(height: 16),
                    _buildInput("Endereço", _enderecoController),
                    const SizedBox(height: 16),
                    _buildInput("Telefone", _telefoneController, keyboardType: TextInputType.phone, inputFormatters: [foneMask]),
                    const SizedBox(height: 16),
                    _buildInput("E-mail", _emailController, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    _buildInput("Senha (Apenas 6 números)", _senhaController, obscureText: true, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
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
                        if (_nomeController.text.isEmpty || _userController.text.isEmpty || _cpfController.text.length < 14 || _senhaController.text.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Preencha todos os campos corretamente! Senha precisa de 6 números.')),
                          );
                          return;
                        }

                        try {
                          final geradorAleatorio = math.Random();
                          final numeroContaGerado = '${geradorAleatorio.nextInt(90000) + 10000}-${geradorAleatorio.nextInt(9)}';

                          final db = DatabaseHelper.instance;
                          
                          Map<String, dynamic> novoUsuario = {
                            'nome': _nomeController.text,
                            'nome_usuario': _userController.text.trim(),
                            'senha': _senhaController.text.trim(),
                            'email': _emailController.text,
                            'telefone': _telefoneController.text,
                            'cpf': _cpfController.text,
                            'data_nascimento': '01/01/2000',
                            'endereco': _enderecoController.text,
                            'cep': '66000-000',
                            'agencia': '0001',
                            'numero_conta': numeroContaGerado,
                            'saldo': 0.0,
                          };

                          await db.gravarUsuario(novoUsuario);

                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Conta criada com sucesso! Faça seu Login.')),
                          );

                          Navigator.pushReplacementNamed(context, '/login');
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro ao salvar. Usuário ou CPF já existem: $e')),
                          );
                        }
                      },
                      child: const Text(
                        "Cadastrar",
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

  Widget _buildInput(String label, TextEditingController controller, {bool obscureText = false, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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