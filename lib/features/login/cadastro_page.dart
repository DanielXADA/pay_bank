import 'dart:io';
import 'dart:convert';
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

  int _etapaAtual = 0;
  bool _buscandoCep = false;

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

  var cpfMask = MaskTextInputFormatter(mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});
  var foneMask = MaskTextInputFormatter(mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});
  var dataMask = MaskTextInputFormatter(mask: '##/##/####', filter: {"#": RegExp(r'[0-9]')});
  var cepMask = MaskTextInputFormatter(mask: '#####-###', filter: {"#": RegExp(r'[0-9]')});

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
    super.dispose();
  }

  Future<void> _buscarCEP() async {
    final cepDigitado = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cepDigitado.length != 8) {
      _mostrarMensagem('Digite um CEP válido com 8 números.');
      return;
    }

    setState(() {
      _buscandoCep = true;
    });

    try {
      final url = Uri.parse('https://viacep.com.br/ws/$cepDigitado/json/');
      final cliente = HttpClient();
      final requisicao = await cliente.getUrl(url);
      final resposta = await requisicao.close();

      if (resposta.statusCode == 200) {
        final corpoResposta = await resposta.transform(utf8.decoder).join();
        final dadosCep = jsonDecode(corpoResposta);

        if (dadosCep['erro'] == true) {
          _mostrarMensagem('CEP não encontrado.');
        } else {
          setState(() {
            _ruaController.text = dadosCep['logradouro'] ?? '';
            _bairroController.text = dadosCep['bairro'] ?? '';
            _cidadeController.text = dadosCep['localidade'] ?? '';
            _estadoController.text = dadosCep['uf'] ?? '';
          });
        }
      } else {
        _mostrarMensagem('Erro ao buscar o CEP.');
      }
    } catch (e) {
      _mostrarMensagem('Erro de conexão ao buscar o CEP.');
    } finally {
      setState(() {
        _buscandoCep = false;
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
      if (_cepController.text.length < 9 || _ruaController.text.trim().isEmpty || _cidadeController.text.trim().isEmpty) {
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

    try {
      String enderecoMontado = _ruaController.text.trim();
      if (_numeroController.text.trim().isNotEmpty) {
        enderecoMontado += ', Nº ${_numeroController.text.trim()}';
      }
      if (_bairroController.text.trim().isNotEmpty) {
        enderecoMontado += ' - ${_bairroController.text.trim()}';
      }
      if (_cidadeController.text.trim().isNotEmpty) {
        enderecoMontado += ', ${_cidadeController.text.trim()}/${_estadoController.text.trim()}';
      }

      final geradorAleatorio = math.Random();
      final numeroContaGerado = '${geradorAleatorio.nextInt(90000) + 10000}-${geradorAleatorio.nextInt(9)}';

      final db = DatabaseHelper.instance;
      
      Map<String, dynamic> novoUsuario = {
        'nome': _nomeController.text.trim(),
        'nome_usuario': _userController.text.trim(),
        'senha': _senhaAcessoController.text.trim(),
        'senha_transacao': _senhaTransacaoController.text.trim(),
        'email': _emailController.text.trim(),
        'telefone': _telefoneController.text.trim(),
        'cpf': _cpfController.text.trim(),
        'data_nascimento': _dataNascimentoController.text.trim(),
        'endereco': enderecoMontado,
        'cep': _cepController.text.trim(),
        'agencia': '0001',
        'numero_conta': numeroContaGerado,
        'saldo': 0.0,
      };

      await db.gravarUsuario(novoUsuario);

      if (!mounted) return;

      _mostrarMensagem('Conta criada com sucesso! Faça seu Login.');
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      _mostrarMensagem('Usuário ou CPF já cadastrado no sistema.');
    }
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  List<Widget> _renderizarEtapaAtual() {
    switch (_etapaAtual) {
      case 0:
        return [
          _buildInput("Nome Completo", _nomeController),
          const SizedBox(height: 16),
          _buildInput("Nome de Usuário (@)", _userController),
          const SizedBox(height: 16),
          _buildInput("CPF", _cpfController, keyboardType: TextInputType.number, inputFormatters: [cpfMask]),
          const SizedBox(height: 16),
          _buildInput("Data de Nascimento", _dataNascimentoController, keyboardType: TextInputType.number, inputFormatters: [dataMask]),
        ];
      case 1:
        return [
          _buildInput("Telefone", _telefoneController, keyboardType: TextInputType.phone, inputFormatters: [foneMask]),
          const SizedBox(height: 16),
          _buildInput("E-mail", _emailController, keyboardType: TextInputType.emailAddress),
        ];
      case 2:
        return [
          Row(
            children: [
              Expanded(
                child: _buildInput("CEP", _cepController, keyboardType: TextInputType.number, inputFormatters: [cepMask]),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _buscandoCep ? null : _buscarCEP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF244A3A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _buscandoCep 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
          _buildInput("Número da Casa", _numeroController, keyboardType: TextInputType.number),
        ];
      case 3:
        return [
          _buildInput(
            "Senha de Acesso (Até 8 dígitos)", 
            _senhaAcessoController, 
            obscureText: _ocultarSenhaAcesso,
            maxLength: 8,
            suffixIcon: IconButton(
              icon: Icon(_ocultarSenhaAcesso ? Icons.visibility : Icons.visibility_off, color: const Color(0xFF757575)),
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
              icon: Icon(_ocultarSenhaTransacao ? Icons.visibility : Icons.visibility_off, color: const Color(0xFF757575)),
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
      case 0: return "Dados Pessoais";
      case 1: return "Canais de Contato";
      case 2: return "Seu Endereço";
      case 3: return "Segurança";
      default: return "Criar Conta";
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
                      onPressed: _etapaAtual == 3 ? _finalizarCadastro : _avancarEtapa,
                      child: Text(
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