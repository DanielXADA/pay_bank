import 'package:flutter/material.dart';
import '../../presentation/viewmodels/profile_viewmodel.dart';

/// View puramente declarativa no padrão MVVM.
///
/// Não faz chamadas HTTP diretas nem queries SQLite.
/// Toda a orquestração cadastral, busca de CEP e autenticação para edição
/// é gerenciada pelo [ProfileViewModel].
class MeusDadosPage extends StatefulWidget {
  const MeusDadosPage({super.key});

  @override
  State<MeusDadosPage> createState() => _MeusDadosPageState();
}

class _MeusDadosPageState extends State<MeusDadosPage> {
  final Color greenPrimary = const Color(0xFF1DB954);
  final Color greenDark = const Color(0xFF191414);
  final Color greyBackground = const Color(0xFFF8F9FA);
  final Color greyText = const Color(0xFF6C757D);

  late final ProfileViewModel _viewModel;
  bool _inicializado = false;
  bool _editando = false;

  final _controladorEmail = TextEditingController();
  final _controladorCelular = TextEditingController();
  final _controladorCep = TextEditingController();
  final _controladorRua = TextEditingController();
  final _controladorBairro = TextEditingController();
  final _controladorCidade = TextEditingController();
  final _controladorEstado = TextEditingController();
  final _controladorNumero = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel();
    _viewModel.addListener(_onViewModelStateChanged);
  }

  void _onViewModelStateChanged() {
    if (!mounted) return;

    if (_viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage!),
          backgroundColor: Colors.redAccent.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _viewModel.clearError();
    } else if (_viewModel.successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.successMessage!),
          backgroundColor: greenPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _viewModel.clearSuccess();
    }

    if (_viewModel.currentUser != null) {
      final user = _viewModel.currentUser!;
      if (!_editando) {
        _controladorEmail.text = user.email;
        _controladorCelular.text = user.phone;
        _controladorCep.text = user.address.cep;
        _controladorRua.text = user.address.street;
        _controladorBairro.text = user.address.neighborhood;
        _controladorCidade.text = user.address.city;
        _controladorEstado.text = user.address.state;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inicializado) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['nome_usuario'] != null) {
        _viewModel.loadUser(args['nome_usuario']);
      }
      _inicializado = true;
    }
  }

  @override
  void dispose() {
    _controladorEmail.dispose();
    _controladorCelular.dispose();
    _controladorCep.dispose();
    _controladorRua.dispose();
    _controladorBairro.dispose();
    _controladorCidade.dispose();
    _controladorEstado.dispose();
    _controladorNumero.dispose();
    _viewModel.removeListener(_onViewModelStateChanged);
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _buscarCEP() async {
    final cepDigitado = _controladorCep.text.trim();
    final ok = await _viewModel.searchCep(cepDigitado);

    if (ok && mounted && _viewModel.searchedAddress != null) {
      final addr = _viewModel.searchedAddress!;
      setState(() {
        _controladorRua.text = addr.street;
        _controladorBairro.text = addr.neighborhood;
        _controladorCidade.text = addr.city;
        _controladorEstado.text = addr.state;
      });
    }
  }

  void _solicitarSenhaParaEditar() {
    final controladorSenha = TextEditingController();
    bool ocultarSenha = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                'Confirmar Identidade',
                style: TextStyle(color: greenDark, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Digite sua senha de acesso para liberar a edição cadastral.',
                    style: TextStyle(color: greyText, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controladorSenha,
                    obscureText: ocultarSenha,
                    maxLength: 8,
                    decoration: InputDecoration(
                      labelText: 'Senha de Acesso',
                      labelStyle: TextStyle(color: greyText),
                      suffixIcon: IconButton(
                        icon: Icon(ocultarSenha ? Icons.visibility_off : Icons.visibility, color: greyText),
                        onPressed: () {
                          setDialogState(() {
                            ocultarSenha = !ocultarSenha;
                          });
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: greenPrimary, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final senha = controladorSenha.text.trim();
                    final valida = await _viewModel.verifyCurrentPassword(senha);

                    if (valida) {
                      if (dialogCtx.mounted) {
                        Navigator.pop(dialogCtx);
                      }
                      if (mounted) {
                        setState(() {
                          _editando = true;
                        });
                      }
                    } else {
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Senha incorreta! Acesso negado.')),
                        );
                      }
                    }
                  },
                  child: Text('Confirmar', style: TextStyle(color: greenPrimary, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _salvarAlteracoes() async {
    if (_controladorEmail.text.trim().isEmpty || _controladorCelular.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail e Celular são obrigatórios.')),
      );
      return;
    }

    String enderecoMontado = _controladorRua.text.trim();
    if (_controladorNumero.text.trim().isNotEmpty) {
      enderecoMontado += ', Nº ${_controladorNumero.text.trim()}';
    }
    if (_controladorBairro.text.trim().isNotEmpty) {
      enderecoMontado += ' - ${_controladorBairro.text.trim()}';
    }
    if (_controladorCidade.text.trim().isNotEmpty) {
      enderecoMontado += ', ${_controladorCidade.text.trim()}/${_controladorEstado.text.trim()}';
    }

    final user = _viewModel.currentUser!;
    final ok = await _viewModel.updateProfileData(
      name: user.name,
      email: _controladorEmail.text,
      phone: _controladorCelular.text,
      cep: _controladorCep.text,
      fullAddress: enderecoMontado,
    );

    if (ok && mounted) {
      setState(() {
        _editando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final user = _viewModel.currentUser;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Meus Dados',
              style: TextStyle(color: greenDark, fontWeight: FontWeight.bold),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: greenDark),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (!_editando)
                IconButton(
                  icon: Icon(Icons.edit, color: greenPrimary),
                  onPressed: _solicitarSenhaParaEditar,
                ),
            ],
          ),
          body: _viewModel.isLoading && user == null
              ? Center(child: CircularProgressIndicator(color: greenPrimary))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge de Dados Verificados (KYC)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: greyBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.shield, color: greenPrimary, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cadastro Bancário Oficial',
                                    style: TextStyle(color: greenDark, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'CPF e Nome completo são imutáveis por regulação do Banco Central.',
                                    style: TextStyle(color: greyText, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      _campoVisual('Nome Completo', user?.name ?? ''),
                      const SizedBox(height: 15),
                      _campoVisual('CPF', user?.cpf ?? ''),
                      const SizedBox(height: 15),
                      _campoVisual('Data de Nascimento', user?.birthDate ?? ''),
                      const SizedBox(height: 15),
                      _campoVisual('Agência e Conta', 'Ag. ${user?.agency ?? '0001'} | Conta ${user?.accountNumber ?? ''}'),
                      const SizedBox(height: 25),
                      const Divider(),
                      const SizedBox(height: 15),
                      Text(
                        'Canais de Contato e Endereço',
                        style: TextStyle(color: greenDark, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15),
                      _campoEditavel('E-mail', _controladorEmail, TextInputType.emailAddress),
                      const SizedBox(height: 15),
                      _campoEditavel('Celular', _controladorCelular, TextInputType.phone),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: _campoEditavel('CEP', _controladorCep, TextInputType.number),
                          ),
                          if (_editando) ...[
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 55,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: greenPrimary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: _viewModel.isSearchingCep ? null : _buscarCEP,
                                child: _viewModel.isSearchingCep
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Buscar', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 15),
                      _campoEditavel('Endereço / Logradouro', _controladorRua, TextInputType.text),
                      if (_editando) ...[
                        const SizedBox(height: 15),
                        _campoEditavel('Número', _controladorNumero, TextInputType.number),
                        const SizedBox(height: 15),
                        _campoEditavel('Bairro', _controladorBairro, TextInputType.text),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(flex: 3, child: _campoEditavel('Cidade', _controladorCidade, TextInputType.text)),
                            const SizedBox(width: 10),
                            Expanded(flex: 1, child: _campoEditavel('UF', _controladorEstado, TextInputType.text)),
                          ],
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: greenPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _viewModel.isLoading ? null : _salvarAlteracoes,
                            child: _viewModel.isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Salvar Alterações', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            onPressed: () => setState(() => _editando = false),
                            child: const Text('Cancelar Edição', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _campoVisual(String label, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: greyText, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: greyBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(valor, style: TextStyle(color: greenDark, fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _campoEditavel(String label, TextEditingController controller, TextInputType keyboardType) {
    return TextField(
      controller: controller,
      enabled: _editando,
      keyboardType: keyboardType,
      style: TextStyle(color: greenDark, fontSize: 15, fontWeight: _editando ? FontWeight.normal : FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: greyText),
        filled: true,
        fillColor: _editando ? Colors.white : greyBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: greenPrimary, width: 2),
        ),
      ),
    );
  }
}