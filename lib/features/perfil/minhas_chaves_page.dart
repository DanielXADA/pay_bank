import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../presentation/viewmodels/profile_viewmodel.dart';

/// View puramente declarativa no padrão MVVM.
///
/// Não acessa SQLite nem SharedPreferences. Delega a gestão de chaves PIX
/// e a validação de segurança transacional para o [ProfileViewModel].
class MinhasChavesPage extends StatefulWidget {
  const MinhasChavesPage({super.key});

  @override
  State<MinhasChavesPage> createState() => _MinhasChavesPageState();
}

class _MinhasChavesPageState extends State<MinhasChavesPage> {
  final Color greenPrimary = const Color(0xFF1DB954);
  final Color greenDark = const Color(0xFF191414);
  final Color greyBackground = const Color(0xFFF8F9FA);
  final Color greyText = const Color(0xFF6C757D);

  late final ProfileViewModel _viewModel;
  bool _inicializado = false;

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inicializado) {
      final dadosIniciais = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (dadosIniciais != null && dadosIniciais['nome_usuario'] != null) {
        _viewModel.loadUser(dadosIniciais['nome_usuario']);
      }
      _inicializado = true;
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelStateChanged);
    _viewModel.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _obterChavesAtivas() {
    final user = _viewModel.currentUser;
    if (user == null) return [];

    final List<Map<String, dynamic>> chaves = [];

    if (user.isCpfKeyActive) {
      chaves.add({
        'tipo': 'CPF',
        'valor': user.cpf,
        'icone': Icons.badge,
        'fixa': true,
      });
    }

    if (user.isPhoneKeyActive) {
      chaves.add({
        'tipo': 'Celular',
        'valor': user.phone,
        'icone': Icons.phone_android,
        'fixa': false,
      });
    }

    if (user.isEmailKeyActive) {
      chaves.add({
        'tipo': 'E-mail',
        'valor': user.email,
        'icone': Icons.email,
        'fixa': false,
      });
    }

    if (user.randomPixKey != null && user.randomPixKey!.isNotEmpty) {
      chaves.add({
        'tipo': 'Aleatória',
        'valor': user.randomPixKey!,
        'icone': Icons.vpn_key,
        'fixa': false,
      });
    }

    return chaves;
  }

  String _gerarChaveAleatoria() {
    final r = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';

    return List.generate(32, (index) {
      if (index == 8 || index == 12 || index == 16 || index == 20) {
        return '-';
      }
      return chars[r.nextInt(chars.length)];
    }).join('');
  }

  bool _chaveJaAtiva(String tipo) {
    final user = _viewModel.currentUser;
    if (user == null) return false;

    if (tipo == 'CPF') return user.isCpfKeyActive;
    if (tipo == 'Celular') return user.isPhoneKeyActive;
    if (tipo == 'E-mail') return user.isEmailKeyActive;

    return user.randomPixKey != null && user.randomPixKey!.isNotEmpty;
  }

  void _solicitarPinSeguranca({required VoidCallback onAuthorized}) {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Confirmação de Segurança', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Digite seu PIN de 6 dígitos para autorizar a alteração de chave PIX:'),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                obscureText: true,
                maxLength: 6,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'PIN de Transação',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: greenPrimary),
              onPressed: () async {
                final pin = pinController.text.trim();
                final valido = await _viewModel.verifyTransactionPin(pin);

                if (!mounted) return;

                if (!valido) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN incorreto. Ação cancelada.')),
                  );
                  return;
                }

                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                }
                onAuthorized();
              },
              child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _excluirChave(Map<String, dynamic> chave) {
    final tipo = chave['tipo'];

    if (tipo == 'CPF') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A chave CPF é padrão da conta e não pode ser removida.')),
      );
      return;
    }

    _solicitarPinSeguranca(
      onAuthorized: () async {
        final user = _viewModel.currentUser!;
        await _viewModel.updatePixKeys(
          isCpfActive: user.isCpfKeyActive,
          isEmailActive: tipo == 'E-mail' ? false : user.isEmailKeyActive,
          isPhoneActive: tipo == 'Celular' ? false : user.isPhoneKeyActive,
          randomKey: tipo == 'Aleatória' ? '' : user.randomPixKey,
        );
      },
    );
  }

  void _mostrarModalCadastro() {
    String tipoSelecionado = 'Celular';
    final TextEditingController controlador = TextEditingController();
    final tiposPermitidos = ['Celular', 'E-mail', 'Aleatória'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (tipoSelecionado == 'Aleatória' && controlador.text.isEmpty) {
              controlador.text = _gerarChaveAleatoria();
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      'Cadastrar Nova Chave',
                      style: TextStyle(color: greenDark, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: tiposPermitidos.map((tipo) {
                        final ativo = tipoSelecionado == tipo;
                        final jaAtiva = _chaveJaAtiva(tipo);

                        return ChoiceChip(
                          label: Text(
                            jaAtiva ? '$tipo cadastrada' : tipo,
                            style: TextStyle(
                              color: ativo ? Colors.white : greenDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: ativo,
                          selectedColor: greenPrimary,
                          backgroundColor: greyBackground,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: ativo ? greenPrimary : Colors.grey[300]!),
                          ),
                          onSelected: jaAtiva
                              ? null
                              : (val) {
                                  setModalState(() {
                                    tipoSelecionado = tipo;
                                    controlador.text = tipo == 'Aleatória' ? _gerarChaveAleatoria() : '';
                                  });
                                },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: greenPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          Navigator.pop(bottomSheetCtx);
                          _solicitarPinSeguranca(
                            onAuthorized: () async {
                              final user = _viewModel.currentUser!;
                              await _viewModel.updatePixKeys(
                                isCpfActive: user.isCpfKeyActive,
                                isEmailActive: tipoSelecionado == 'E-mail' ? true : user.isEmailKeyActive,
                                isPhoneActive: tipoSelecionado == 'Celular' ? true : user.isPhoneKeyActive,
                                randomKey: tipoSelecionado == 'Aleatória' ? controlador.text : user.randomPixKey,
                              );
                            },
                          );
                        },
                        child: const Text('Confirmar Cadastro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final chavesAtivas = _obterChavesAtivas();

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Minhas Chaves PIX',
              style: TextStyle(color: greenDark, fontWeight: FontWeight.bold),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: greenDark),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: _viewModel.isLoading && _viewModel.currentUser == null
              ? Center(child: CircularProgressIndicator(color: greenPrimary))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: greenPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.shield_outlined, color: greenPrimary, size: 30),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Diretório de Chaves do PayBank',
                                    style: TextStyle(color: greenDark, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Suas chaves vinculam pagamentos instantâneos com liquidação no Ledger.',
                                    style: TextStyle(color: greyText, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'Chaves Cadastradas',
                        style: TextStyle(color: greenDark, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15),
                      ...chavesAtivas.map((chave) => _buildChaveItem(chave)),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _mostrarModalCadastro,
                          icon: Icon(Icons.add, color: greenPrimary),
                          label: Text(
                            'Cadastrar Nova Chave',
                            style: TextStyle(color: greenPrimary, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: greenPrimary, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildChaveItem(Map<String, dynamic> chave) {
    final fixa = chave['fixa'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: greyBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(chave['icone'] as IconData, color: greenPrimary),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chave['tipo'] as String,
                  style: TextStyle(color: greenDark, fontWeight: FontWeight.bold),
                ),
                Text(
                  chave['valor'] as String,
                  style: TextStyle(color: greyText, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!fixa)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _excluirChave(chave),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Padrão', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ),
        ],
      ),
    );
  }
}