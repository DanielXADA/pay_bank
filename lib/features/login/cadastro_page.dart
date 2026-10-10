import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:pay_bank/widgets/bouncing_button.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';

/// View puramente declarativa no padrão MVVM.
///
/// Não contém requisições HTTP diretas, regras de formatação de tabelas SQLite ou HttpClient.
/// Todas as consultas e regras são orquestradas pelo [AuthViewModel].
class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> with TickerProviderStateMixin {
  late final AnimationController _controller1;
  late final AnimationController _controller2;

  late final AuthViewModel _viewModel;

  int _etapaAtual = 0;

  final _nomeController = TextEditingController();
  final _userController = TextEditingController();
  final _cpfController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();

  final _cepController = TextEditingController();
  final _ruaController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  final _numeroController = TextEditingController();

  final _senhaAcessoController = TextEditingController();
  final _senhaTransacaoController = TextEditingController();

  bool _ocultarSenhaAcesso = true;
  bool _ocultarSenhaTransacao = true;

  final cpfMask = MaskTextInputFormatter(mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});
  final foneMask = MaskTextInputFormatter(mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});
  final dataMask = MaskTextInputFormatter(mask: '##/##/####', filter: {"#": RegExp(r'[0-9]')});
  final cepMask = MaskTextInputFormatter(mask: '#####-###', filter: {"#": RegExp(r'[0-9]')});

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
  }

  void _onViewModelStateChanged() {
    if (!mounted) return;

    if (_viewModel.errorMessage != null) {
      _mostrarMensagem(_viewModel.errorMessage!, isError: true);
      _viewModel.clearError();
    } else if (_viewModel.successMessage != null) {
      _mostrarMensagem(_viewModel.successMessage!, isError: false);
      _viewModel.clearSuccess();
    }
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _nomeController.dispose();
    _userController.dispose();
    _cpfController.dispose();
    _dataNascimentoController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _cepController.dispose();
    _ruaController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    _numeroController.dispose();
    _senhaAcessoController.dispose();
    _senhaTransacaoController.dispose();
    _viewModel.removeListener(_onViewModelStateChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _mostrarMensagem(String texto, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: isError ? Colors.redAccent.shade700 : const Color(0xFF3FA168),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _buscarCEP() async {
    final cepDigitado = _cepController.text.trim();

    final sucesso = await _viewModel.searchCep(cepDigitado);

    if (sucesso && mounted && _viewModel.searchedAddress != null) {
      final endereco = _viewModel.searchedAddress!;
      setState(() {
        _ruaController.text = endereco.street;
        _bairroController.text = endereco.neighborhood;
        _cidadeController.text = endereco.city;
        _estadoController.text = endereco.state;
      });
    }
  }

  void _avancarEtapa() {
    if (_etapaAtual == 0) {
      if (_nomeController.text.trim().isEmpty ||
          _userController.text.trim().isEmpty ||
          _cpfController.text.length < 14 ||
          _dataNascimentoController.text.length < 10) {
        _mostrarMensagem('Preencha todos os dados pessoais corretamente.');
        return;
      }
    } else if (_etapaAtual == 1) {
      if (_telefoneController.text.length < 14 || _emailController.text.trim().isEmpty) {
        _mostrarMensagem('Informe canais de contato válidos.');
        return;
      }
    } else if (_etapaAtual == 2) {
      if (_cepController.text.length < 9 ||
          _ruaController.text.trim().isEmpty ||
          _cidadeController.text.trim().isEmpty) {
        _mostrarMensagem('Preencha os dados de endereço. Busque pelo CEP.');
        return;
      }
    }

    setState(() {
      _etapaAtual++;
    });
  }

  void _voltarEtapa() {
    if (_etapaAtual > 0) {
      setState(() {
        _etapaAtual--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _finalizarCadastro() async {
    if (_senhaAcessoController.text.isEmpty || _senhaTransacaoController.text.length != 6) {
      _mostrarMensagem('Crie suas senhas de acesso e transação corretamente.');
      return;
    }

    final sucesso = await _viewModel.registerUser(
      name: _nomeController.text,
      username: _userController.text,
      email: _emailController.text,
      phone: _telefoneController.text,
      cpf: _cpfController.text,
      birthDate: _dataNascimentoController.text,
      cep: _cepController.text,
      street: _ruaController.text,
      number: _numeroController.text,
      neighborhood: _bairroController.text,
      city: _cidadeController.text,
      state: _estadoController.text,
      password: _senhaAcessoController.text,
      transactionPassword: _senhaTransacaoController.text,
    );

    if (sucesso && mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  List<Widget> _renderizarEtapaAtual() {
    switch (_etapaAtual) {
      case 0:
        return [
          _buildInput("Nome Completo", _nomeController),
          const SizedBox(height: 16),
          _buildInput("Nome de Usuário (@)", _userController),
          const SizedBox(height: 16),
          _buildInput(
            "CPF",
            _cpfController,
            keyboardType: TextInputType.number,
            inputFormatters: [cpfMask],
          ),
          const SizedBox(height: 16),
          _buildInput(
            "Data de Nascimento",
            _dataNascimentoController,
            keyboardType: TextInputType.number,
            inputFormatters: [dataMask],
          ),
        ];
      case 1:
        return [
          _buildInput(
            "Telefone",
            _telefoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [foneMask],
          ),
          const SizedBox(height: 16),
          _buildInput(
            "E-mail",
            _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
        ];
      case 2:
        return [
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  "CEP",
                  _cepController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [cepMask],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _viewModel.isSearchingCep ? null : _buscarCEP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF244A3A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _viewModel.isSearchingCep
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Buscar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInput("Logradouro/Rua", _ruaController),
          const SizedBox(height: 16),
          _buildInput("Bairro", _bairroController),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(flex: 3, child: _buildInput("Cidade", _cidadeController)),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: _buildInput("UF", _estadoController)),
            ],
          ),
          const SizedBox(height: 16),
          _buildInput(
            "Número da Casa",
            _numeroController,
            keyboardType: TextInputType.number,
          ),
        ];
      case 3:
        return [
          _buildInput(
            "Senha de Acesso (Até 8 dígitos)",
            _senhaAcessoController,
            obscureText: _ocultarSenhaAcesso,
            maxLength: 8,
            suffixIcon: IconButton(
              icon: Icon(
                _ocultarSenhaAcesso ? Icons.visibility : Icons.visibility_off,
                color: const Color(0xFF757575),
              ),
              onPressed: () => setState(() => _ocultarSenhaAcesso = !_ocultarSenhaAcesso),
            ),
          ),
          const SizedBox(height: 16),
          _buildInput(
            "Senha de Transação (6 números)",
            _senhaTransacaoController,
            obscureText: _ocultarSenhaTransacao,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            suffixIcon: IconButton(
              icon: Icon(
                _ocultarSenhaTransacao ? Icons.visibility : Icons.visibility_off,
                color: const Color(0xFF757575),
              ),
              onPressed: () => setState(() => _ocultarSenhaTransacao = !_ocultarSenhaTransacao),
            ),
          ),
        ];
      default:
        return [];
    }
  }

  String _obterTituloEtapa() {
    switch (_etapaAtual) {
      case 0:
        return "Dados Pessoais";
      case 1:
        return "Canais de Contato";
      case 2:
        return "Seu Endereço";
      case 3:
        return "Segurança";
      default:
        return "Criar Conta";
    }
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: _voltarEtapa,
            ),
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
                      title: _obterTituloEtapa(),
                      children: [
                        ..._renderizarEtapaAtual(),
                        const SizedBox(height: 30),
                        BouncingButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4F85A),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _viewModel.isLoading
                              ? null
                              : (_etapaAtual == 3 ? _finalizarCadastro : _avancarEtapa),
                          child: _viewModel.isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.black,
                                  ),
                                )
                              : Text(
                                  _etapaAtual == 3 ? "Finalizar Cadastro" : "Continuar",
                                  style: const TextStyle(
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