import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../presentation/viewmodels/transfer_viewmodel.dart';

/// View puramente declarativa no padrão MVVM.
///
/// Não executa queries SQL, mutações de saldo nem gravações manuais.
/// Toda a regra de validação, geração de idempotency key e execução atômica
/// é orquestrada pelo [TransferViewModel].
class TransferenciaPage extends StatefulWidget {
  const TransferenciaPage({super.key});

  @override
  State<TransferenciaPage> createState() => _TransferenciaPageState();
}

class _TransferenciaPageState extends State<TransferenciaPage> {
  late final TransferViewModel _viewModel;

  final _controladorChave = TextEditingController();
  final _controladorValor = TextEditingController();
  final _controladorSenhaTransacao = TextEditingController();

  String _tipoChaveSelecionada = 'CPF';

  final Color greenPrimary = const Color(0xFF1DB954);
  final Color greenDark = const Color(0xFF191414);
  final Color greyBackground = const Color(0xFFF8F9FA);
  final Color greyText = const Color(0xFF6C757D);

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _viewModel = TransferViewModel();
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _viewModel.clearError();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _initialized = true;
      final dadosIniciais = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (dadosIniciais != null && dadosIniciais['nome_usuario'] != null) {
        _viewModel.initSender(dadosIniciais['nome_usuario']);
      }
    }
  }

  @override
  void dispose() {
    _controladorChave.dispose();
    _controladorValor.dispose();
    _controladorSenhaTransacao.dispose();
    _viewModel.removeListener(_onViewModelStateChanged);
    _viewModel.dispose();
    super.dispose();
  }

  TextInputFormatter _obterMascaraPorTipo() {
    if (_tipoChaveSelecionada == 'CPF') {
      return TextInputFormatter.withFunction((oldValue, newValue) {
        final text = newValue.text.replaceAll(RegExp(r'\D'), '');

        if (text.length > 11) return oldValue;

        String formatted = '';

        for (int i = 0; i < text.length; i++) {
          if (i == 3 || i == 6) formatted += '.';
          if (i == 9) formatted += '-';
          formatted += text[i];
        }

        return TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      });
    } else if (_tipoChaveSelecionada == 'Celular') {
      return TextInputFormatter.withFunction((oldValue, newValue) {
        final text = newValue.text.replaceAll(RegExp(r'\D'), '');

        if (text.length > 11) return oldValue;

        String formatted = '';

        for (int i = 0; i < text.length; i++) {
          if (i == 0) formatted += '(';
          if (i == 2) formatted += ') ';
          if (i == 7) formatted += '-';
          formatted += text[i];
        }

        return TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      });
    }

    return TextInputFormatter.withFunction((oldValue, newValue) => newValue);
  }

  TextInputType _obterTecladoPorTipo() {
    if (_tipoChaveSelecionada == 'CPF' || _tipoChaveSelecionada == 'Celular') {
      return TextInputType.number;
    } else if (_tipoChaveSelecionada == 'E-mail') {
      return TextInputType.emailAddress;
    }

    return TextInputType.text;
  }

  String _formatarMoedaPtBr(double valor) {
    String valorFixo = valor.toStringAsFixed(2);
    List<String> partes = valorFixo.split('.');
    String inteira = partes[0];
    String decimal = partes[1];

    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    inteira = inteira.replaceAllMapped(reg, (Match match) => '${match[1]}.');

    return '$inteira,$decimal';
  }

  String _mascararCpf(String? cpf) {
    if (cpf == null || cpf.length < 11) return cpf ?? 'Não informado';
    final digits = cpf.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '***.${digits.substring(3, 6)}.***-${digits.substring(9, 11)}';
    }
    return cpf;
  }

  double _lerValorTransferencia() {
    final valorText = _controladorValor.text
        .replaceAll('.', '')
        .replaceAll(',', '.');

    return double.tryParse(valorText) ?? 0.0;
  }

  void _compartilharComprovante({
    required double valor,
    required String data,
    required String idTransacao,
  }) {
    final sender = _viewModel.senderUser;
    final receiver = _viewModel.receiverUser;

    if (sender == null || receiver == null) return;

    final textoComprovante = '''
Comprovante PIX - PayBank

Transferência realizada com sucesso via Core Banking Ledger.

Valor: R\$ ${_formatarMoedaPtBr(valor)}
Pagador: ${sender.name}
Recebedor: ${receiver.name}
CPF do recebedor: ${_mascararCpf(receiver.cpf)}
Instituição: PayBank
Agência: ${receiver.agency}
Conta: ${receiver.accountNumber}
Data e hora: $data
ID da transação: $idTransacao
Idempotency Key: ${_viewModel.idempotencyKey ?? 'N/A'}
''';

    Share.share(textoComprovante);
  }

  Future<void> _validarERevisar() async {
    final chave = _controladorChave.text.trim();
    final valorTransferencia = _lerValorTransferencia();

    final ok = await _viewModel.validateAndReview(
      keyType: _tipoChaveSelecionada,
      key: chave,
      amountValue: valorTransferencia,
    );

    if (ok && mounted) {
      _mostrarRevisaoPix(valorTransferencia);
    }
  }

  void _mostrarRevisaoPix(double valorTransferencia) {
    final sender = _viewModel.senderUser;
    final receiver = _viewModel.receiverUser;

    if (sender == null || receiver == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  'Revise seu PIX',
                  style: TextStyle(
                    color: greenDark,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),
                _linhaRevisao(
                  'Valor',
                  'R\$ ${_formatarMoedaPtBr(valorTransferencia)}',
                ),
                _linhaRevisao('De', sender.name),
                _linhaRevisao('Para', receiver.name),
                _linhaRevisao(
                  'CPF',
                  _mascararCpf(receiver.cpf),
                ),
                _linhaRevisao(
                  'Conta',
                  'Ag. ${receiver.agency} | Conta ${receiver.accountNumber}',
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: greenPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(bottomSheetCtx);
                      _mostrarSenhaTransacao(valorTransferencia);
                    },
                    child: const Text(
                      'Confirmar Dados',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _linhaRevisao(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: greyText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: greenDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarSenhaTransacao(double valorTransferencia) {
    _controladorSenhaTransacao.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Senha de Transação'),
          content: TextField(
            controller: _controladorSenhaTransacao,
            obscureText: true,
            maxLength: 6,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Digite sua senha de 6 dígitos',
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: greenPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final pin = _controladorSenhaTransacao.text.trim();

                final pinOk = await _viewModel.verifyTransactionPin(pin);
                if (!pinOk) {
                  return;
                }

                Navigator.pop(dialogCtx);
                final sucesso = await _viewModel.executeTransfer();

                if (sucesso && mounted && _viewModel.completedTransaction != null) {
                  final tx = _viewModel.completedTransaction!;
                  final dataFormatada = '${tx.createdAt.day.toString().padLeft(2, '0')}/${tx.createdAt.month.toString().padLeft(2, '0')}/${tx.createdAt.year} às ${tx.createdAt.hour.toString().padLeft(2, '0')}:${tx.createdAt.minute.toString().padLeft(2, '0')}';

                  _mostrarComprovantePix(
                    valor: valorTransferencia,
                    data: dataFormatada,
                    idTransacao: tx.id,
                  );
                }
              },
              child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _mostrarComprovantePix({
    required double valor,
    required String data,
    required String idTransacao,
  }) {
    final sender = _viewModel.senderUser;
    final receiver = _viewModel.receiverUser;

    if (sender == null || receiver == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: greenPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 60,
                    color: greenPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'PIX Enviado!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'R\$ ${_formatarMoedaPtBr(valor)}',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: greenPrimary,
                  ),
                ),
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: greyBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _linhaComprovante('Pagador', sender.name),
                      const Divider(height: 20),
                      _linhaComprovante('Recebedor', receiver.name),
                      const Divider(height: 20),
                      _linhaComprovante('CPF', _mascararCpf(receiver.cpf)),
                      const Divider(height: 20),
                      _linhaComprovante(
                        'Conta',
                        'Ag. ${receiver.agency} | ${receiver.accountNumber}',
                      ),
                      const Divider(height: 20),
                      _linhaComprovante('Data', data),
                      const Divider(height: 20),
                      _linhaComprovante('ID', idTransacao),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton.icon(
              onPressed: () => _compartilharComprovante(
                valor: valor,
                data: data,
                idTransacao: idTransacao,
              ),
              icon: Icon(Icons.share, color: greenPrimary),
              label: Text(
                'Compartilhar',
                style: TextStyle(
                  color: greenPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: greenDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text(
                'Fechar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _linhaComprovante(String label, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: greyText)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            valor,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: greenDark,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final saldoDisponivel = _viewModel.senderAccount?.balance.toDouble() ?? 0.0;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Área PIX',
              style: TextStyle(
                color: greenDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: greenDark),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: greenPrimary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: greenPrimary.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Saldo disponível para envio',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'R\$ ${_formatarMoedaPtBr(saldoDisponivel)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 35),
                Text(
                  '1. Qual é o tipo de chave?',
                  style: TextStyle(
                    color: greenDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['CPF', 'Celular', 'E-mail', 'Aleatória'].map((tipo) {
                      bool ativo = _tipoChaveSelecionada == tipo;

                      return Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: ChoiceChip(
                          label: Text(
                            tipo,
                            style: TextStyle(
                              color: ativo ? Colors.white : greenDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: ativo,
                          selectedColor: greenPrimary,
                          backgroundColor: greyBackground,
                          elevation: 0,
                          pressElevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: ativo ? greenPrimary : Colors.grey[300]!,
                            ),
                          ),
                          onSelected: (val) {
                            setState(() {
                              _tipoChaveSelecionada = tipo;
                              _controladorChave.clear();
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 35),
                Text(
                  '2. Insira os dados',
                  style: TextStyle(
                    color: greenDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _controladorChave,
                  keyboardType: _obterTecladoPorTipo(),
                  inputFormatters: [_obterMascaraPorTipo()],
                  style: TextStyle(
                    color: greenDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Chave $_tipoChaveSelecionada',
                    labelStyle: TextStyle(color: greyText),
                    hintText: _tipoChaveSelecionada == 'CPF'
                        ? '000.000.000-00'
                        : (_tipoChaveSelecionada == 'Celular'
                            ? '(00) 00000-0000'
                            : 'Digite aqui...'),
                    prefixIcon: Icon(
                      Icons.vpn_key_rounded,
                      color: greenPrimary,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: greenPrimary,
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _controladorValor,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [CentavosInputFormatter()],
                  style: TextStyle(
                    color: greenPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Valor da Transferência',
                    labelStyle: TextStyle(color: greyText, fontSize: 14),
                    prefixText: 'R\$ ',
                    prefixStyle: TextStyle(
                      color: greenPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    prefixIcon: Icon(
                      Icons.attach_money_rounded,
                      color: greenPrimary,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: greenPrimary,
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: greenPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _viewModel.isLoading ? null : _validarERevisar,
                    child: _viewModel.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Enviar PIX',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.send_rounded, color: Colors.white),
                            ],
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
}

class CentavosInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) return newValue;

    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) return newValue.copyWith(text: '');

    double value = double.parse(digitsOnly) / 100;
    String newText = value.toStringAsFixed(2).replaceAll('.', ',');

    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');

    newText = newText.replaceAllMapped(
      reg,
      (Match match) => '${match[1]}.',
    );

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}