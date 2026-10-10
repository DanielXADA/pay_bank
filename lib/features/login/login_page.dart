import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:pay_bank/widgets/bouncing_button.dart';
import '../../data/models/user_model.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';

/// View puramente declarativa no padrão MVVM.
///
/// Não contém regras de negócio, queries SQLite, SharedPreferences ou chamada a plugins nativos.
/// Toda a orquestração e gerenciamento de estado é delegada para o [AuthViewModel].
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

  late final AuthViewModel _viewModel;

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

    _viewModel = AuthViewModel();
    _viewModel.addListener(_onViewModelStateChanged);

    _inicializarDados();
  }

  Future<void> _inicializarDados() async {
    await _viewModel.loadLastSavedUsername();
    if (mounted && _viewModel.lastSavedUsername != null && _viewModel.lastSavedUsername!.isNotEmpty) {
      _usuarioController.text = _viewModel.lastSavedUsername!;
    }
  }

  void _onViewModelStateChanged() {
    if (!mounted) return;

    if (_viewModel.errorMessage != null) {
      _exibirMensagem(_viewModel.errorMessage!, isError: true);
      _viewModel.clearError();
    } else if (_viewModel.successMessage != null) {
      _exibirMensagem(_viewModel.successMessage!, isError: false);
      _viewModel.clearSuccess();
    }
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _usuarioController.dispose();
    _senhaController.dispose();
    _viewModel.removeListener(_onViewModelStateChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _exibirMensagem(String mensagem, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isError ? Colors.redAccent.shade700 : const Color(0xFF3FA168),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _fazerLoginNormal() async {
    final sucesso = await _viewModel.login(
      _usuarioController.text,
      _senhaController.text,
    );

    if (sucesso && mounted && _viewModel.currentUser != null) {
      final userMap = UserModel.fromDomain(_viewModel.currentUser!).toMap();
      userMap['saldo'] = _viewModel.currentUser!.account?.balance.toDouble() ?? 0.0;
      userMap['id'] = _viewModel.currentUser!.id;

      Navigator.pushReplacementNamed(
        context,
        '/principal',
        arguments: userMap,
      );
    }
  }

  Future<void> _entrarComBiometria() async {
    final sucesso = await _viewModel.loginWithBiometrics();

    if (sucesso && mounted && _viewModel.currentUser != null) {
      final userMap = UserModel.fromDomain(_viewModel.currentUser!).toMap();
      userMap['saldo'] = _viewModel.currentUser!.account?.balance.toDouble() ?? 0.0;
      userMap['id'] = _viewModel.currentUser!.id;

      Navigator.pushReplacementNamed(
        context,
        '/principal',
        arguments: userMap,
      );
    }
  }

  void _mostrarDialogoEsqueciSenha() {
    final controladorUser = TextEditingController();
    final controladorCpf = TextEditingController();
    final controladorNascimento = TextEditingController();

    final cpfMask = MaskTextInputFormatter(
      mask: '###.###.###-##',
      filter: {"#": RegExp(r'[0-9]')},
    );

    final dataMask = MaskTextInputFormatter(
      mask: '##/##/####',
      filter: {"#": RegExp(r'[0-9]')},
    );

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Recuperar Senhas', style: TextStyle(fontWeight: FontWeight.bold)),
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
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3FA168),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final username = controladorUser.text.trim();
                final cpf = controladorCpf.text.trim();
                final nascimento = controladorNascimento.text.trim();

                if (username.isEmpty || cpf.isEmpty || nascimento.isEmpty) {
                  _exibirMensagem('Preencha todos os campos para validação.');
                  return;
                }

                Navigator.pop(dialogCtx);
                _mostrarDialogoRedefinirSenhas(username, cpf, nascimento);
              },
              child: const Text('Verificar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoRedefinirSenhas(String username, String cpf, String nascimento) {
    final novaAcessoCtrl = TextEditingController();
    final confirmaAcessoCtrl = TextEditingController();

    bool ocultarAcesso1 = true;
    bool ocultarAcesso2 = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Redefinir Senha de Acesso', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3FA168),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final nAcesso = novaAcessoCtrl.text.trim();
                    final cAcesso = confirmaAcessoCtrl.text.trim();

                    if (nAcesso.isEmpty || nAcesso.length > 8) {
                      _exibirMensagem('A senha deve ter até 8 dígitos.');
                      return;
                    }

                    if (nAcesso != cAcesso) {
                      _exibirMensagem('As senhas digitadas não conferem.');
                      return;
                    }

                    Navigator.pop(dialogCtx);

                    await _viewModel.resetPassword(
                      username: username,
                      cpf: cpf,
                      birthDate: nascimento,
                      newPassword: nAcesso,
                    );
                  },
                  child: const Text('Redefinir Senha', style: TextStyle(color: Colors.white)),
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

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
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
                          onPressed: _viewModel.isLoading ? null : _fazerLoginNormal,
                          child: _viewModel.isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.black,
                                  ),
                                )
                              : const Text(
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
                            color: _viewModel.isLoading ? Colors.grey : Colors.white70,
                          ),
                          onPressed: _viewModel.isLoading ? null : _entrarComBiometria,
                        ),
                        if (_viewModel.lastSavedUsername == null || _viewModel.lastSavedUsername!.isEmpty)
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
              ),
            ],
          ),
        );
      },
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