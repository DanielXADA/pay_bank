import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
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

  bool _ocultarSenha = true;

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

  void _dispararBiometriaSimulada() async {
    final usernameDigitado = _usuarioController.text.trim();

    if (usernameDigitado.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, digite seu Nome de Usuário antes de usar a biometria!')),
      );
      return;
    }

    final bancoDados = DatabaseHelper.instance;
    final usuario = await bancoDados.buscarUsuarioPorLogin(usernameDigitado);

    if (usuario == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('O usuário @$usernameDigitado não foi encontrado no sistema!')),
      );
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.fingerprint, size: 30, color: Colors.green),
              SizedBox(width: 10),
              Text('Autenticação'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Toque no sensor de biometria para acessar a conta de @$usernameDigitado.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              const Icon(Icons.fingerprint, size: 60, color: Colors.green),
              const SizedBox(height: 10),
              const Text('Aguardando leitura...', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); 

                Navigator.pushReplacementNamed(
                  context, 
                  '/principal',
                  arguments: usuario,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Bem-vindo de volta, ${usuario['nome']}!')),
                );
              },
              child: const Text('Simular Toque', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

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
          title: const Text('Recuperar Senhas'),
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
                  _mostrarDialogoRedefinirSenhas(usuario['id']);
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

  void _mostrarDialogoRedefinirSenhas(int idUsuario) {
    final novaAcessoCtrl = TextEditingController();
    final confirmaAcessoCtrl = TextEditingController();
    final novaTransacaoCtrl = TextEditingController();
    final confirmaTransacaoCtrl = TextEditingController();

    bool ocultarAcesso1 = true;
    bool ocultarAcesso2 = true;
    bool ocultarTrans1 = true;
    bool ocultarTrans2 = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Redefinir Senhas'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Nova Senha de Acesso:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: novaAcessoCtrl,
                      obscureText: ocultarAcesso1,
                      maxLength: 8,
                      decoration: InputDecoration(
                        labelText: 'Nova Senha (Max 8 dígitos)',
                        border: const OutlineInputBorder(),
                        counterText: "",
                        suffixIcon: IconButton(
                          icon: Icon(ocultarAcesso1 ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setStateDialog(() => ocultarAcesso1 = !ocultarAcesso1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmaAcessoCtrl,
                      obscureText: ocultarAcesso2,
                      maxLength: 8,
                      decoration: InputDecoration(
                        labelText: 'Confirmar Senha de Acesso',
                        border: const OutlineInputBorder(),
                        counterText: "",
                        suffixIcon: IconButton(
                          icon: Icon(ocultarAcesso2 ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setStateDialog(() => ocultarAcesso2 = !ocultarAcesso2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text('Nova Senha de Transação:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: novaTransacaoCtrl,
                      obscureText: ocultarTrans1,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: 'Nova Senha (6 números)',
                        border: const OutlineInputBorder(),
                        counterText: "",
                        suffixIcon: IconButton(
                          icon: Icon(ocultarTrans1 ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setStateDialog(() => ocultarTrans1 = !ocultarTrans1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmaTransacaoCtrl,
                      obscureText: ocultarTrans2,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: 'Confirmar Senha de Transação',
                        border: const OutlineInputBorder(),
                        counterText: "",
                        suffixIcon: IconButton(
                          icon: Icon(ocultarTrans2 ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setStateDialog(() => ocultarTrans2 = !ocultarTrans2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    final nAcesso = novaAcessoCtrl.text.trim();
                    final cAcesso = confirmaAcessoCtrl.text.trim();
                    final nTrans = novaTransacaoCtrl.text.trim();
                    final cTrans = confirmaTransacaoCtrl.text.trim();

                    if (nAcesso.isEmpty || nAcesso.length > 8 || nAcesso != cAcesso) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verifique a senha de acesso! Ela deve ter até 8 dígitos e ser idêntica nos dois campos.')),
                      );
                      return;
                    }

                    if (nTrans.length != 6 || nTrans != cTrans) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verifique a senha de transação! Ela precisa ter exatamente 6 números e ser idêntica nos dois campos.')),
                      );
                      return;
                    }

                    final bancoDados = DatabaseHelper.instance;
                    await bancoDados.atualizarUsuario(idUsuario, {
                      'senha': nAcesso,
                      'senha_transacao': nTrans,
                    });

                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Senhas redefinidas com sucesso!')),
                    );
                  },
                  child: const Text('Redefinir Senhas'),
                ),
              ],
            );
          }
        );
      },
    );
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
                  _buildInput(
                    "Senha de Acesso", 
                    _senhaController, 
                    obscureText: _ocultarSenha,
                    maxLength: 8,
                    suffixIcon: IconButton(
                      icon: Icon(_ocultarSenha ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _ocultarSenha = !_ocultarSenha),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _mostrarDialogoEsqueciSenha,
                      child: const Text('Esqueceu sua senha?', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(height: 15),
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
                  const SizedBox(height: 20),
                  IconButton(
                    icon: const Icon(Icons.fingerprint, size: 45, color: Colors.white70),
                    onPressed: _dispararBiometriaSimulada, 
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
            color: const Color(0xFF32325D).withValues(alpha: 0.25),
            blurRadius: 50,
            offset: const Offset(0, 30),
            blurStyle: BlurStyle.inner,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
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

  Widget _buildInput(String label, TextEditingController controller, {bool obscureText = false, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters, Widget? suffixIcon, int? maxLength}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      style: const TextStyle(color: Color(0xFF212121), fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        counterText: "",
        labelStyle: const TextStyle(color: Color(0xFF757575)),
        floatingLabelStyle: const TextStyle(color: Color(0xFF3FA168)),
        suffixIcon: suffixIcon,
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