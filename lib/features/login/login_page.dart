import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:pay_bank/widgets/bouncing_button.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _ocultarSenha = true;
  bool _autenticando = false;
  String? _ultimoUsuarioSalvo;

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

    _carregarUltimoUsuario();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _usuarioController.dispose();
    _senhaController.dispose();
    super.dispose();
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
        localizedReason: 'Confirme sua identidade para entrar no PayBank',
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

  void _mostrarDialogoEsqueciSenha() {
    final controladorUser = TextEditingController();
    final controladorCpf = TextEditingController();
    final controladorNascimento = TextEditingController();

    var cpfMask = MaskTextInputFormatter(
      mask: '###.###.###-##',
      filter: {"#": RegExp(r'[0-9]')},
    );

    var dataMask = MaskTextInputFormatter(
      mask: '##/##/####',
      filter: {"#": RegExp(r'[0-9]')},
    );

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
                    const SnackBar(
                      content: Text('Dados incorretos ou usuário não encontrado!'),
                    ),
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

    bool ocultarAcesso1 = true;
    bool ocultarAcesso2 = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Redefinir Senha de Acesso'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Crie sua nova senha de login:',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: novaAcessoCtrl,
                      obscureText: ocultarAcesso1,
                      maxLength: 8,
                      decoration: InputDecoration(
                        labelText: 'Nova Senha (Max 8 dígitos)',
                        border: const OutlineInputBorder(),
                        counterText: "",
                        suffixIcon: IconButton(
                          icon: Icon(
                            ocultarAcesso1 ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setStateDialog(() {
                              ocultarAcesso1 = !ocultarAcesso1;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmaAcessoCtrl,
                      obscureText: ocultarAcesso2,
                      maxLength: 8,
                      decoration: InputDecoration(
                        labelText: 'Confirmar Nova Senha',
                        border: const OutlineInputBorder(),
                        counterText: "",
                        suffixIcon: IconButton(
                          icon: Icon(
                            ocultarAcesso2 ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setStateDialog(() {
                              ocultarAcesso2 = !ocultarAcesso2;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final nAcesso = novaAcessoCtrl.text.trim();
                    final cAcesso = confirmaAcessoCtrl.text.trim();

                    if (nAcesso.isEmpty || nAcesso.length > 8) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('A senha deve ter até 8 dígitos.')),
                      );
                      return;
                    }

                    if (nAcesso != cAcesso) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('As senhas digitadas não são iguais.')),
                      );
                      return;
                    }

                    final bancoDados = DatabaseHelper.instance;

                    await bancoDados.atualizarUsuario(idUsuario, {
                      'senha': nAcesso,
                    });

                    if (!mounted) return;

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Senha de acesso redefinida com sucesso!')),
                    );
                  },
                  child: const Text('Redefinir Senha'),
                ),
              ],
            );
          },
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
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _mostrarDialogoEsqueciSenha,
                      child: const Text(
                        'Esqueceu sua senha?',
                        style: TextStyle(color: Colors.grey),
                      ),
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
                    onPressed: _fazerLoginNormal,
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
                    icon: Icon(
                      Icons.fingerprint,
                      size: 45,
                      color: _autenticando ? Colors.grey : Colors.white70,
                    ),
                    onPressed: _autenticando ? null : _entrarComBiometria,
                  ),
                  // ... (Mantenha o bloco do IconButton da biometria e o texto de aviso dela aqui em cima)
                  if (_ultimoUsuarioSalvo == null || _ultimoUsuarioSalvo!.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Faça login uma vez para ativar a biometria.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                    
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Não tem uma conta? ",
                        style: TextStyle(color: Color(0xFF616161), fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/cadastro');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          "Cadastre-se aqui",
                          style: TextStyle(
                            color: Color(0xFF3FA168),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
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

  Widget _buildInput(
    String label,
    TextEditingController controller, {
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    int? maxLength,
  }) {
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