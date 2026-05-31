import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../database/db_helper.dart';

class TransferenciaPage extends StatefulWidget {
  const TransferenciaPage({super.key});

  @override
  State<TransferenciaPage> createState() => _TransferenciaPageState();
}

class _TransferenciaPageState extends State<TransferenciaPage> {
  Map<String, dynamic>? _usuarioDados;
  Map<String, dynamic>? _usuarioRecebedor;

  final _controladorChave = TextEditingController();
  final _controladorValor = TextEditingController();
  final _controladorSenhaTransacao = TextEditingController();

  String _tipoChaveSelecionada = 'CPF';

  final Color greenPrimary = const Color(0xFF1DB954);
  final Color greenDark = const Color(0xFF191414);
  final Color greyBackground = const Color(0xFFF8F9FA);
  final Color greyText = const Color(0xFF6C757D);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _usuarioDados ??=
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  }

  @override
  void dispose() {
    _controladorChave.dispose();
    _controladorValor.dispose();
    _controladorSenhaTransacao.dispose();
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

  String _mascararCpf(String cpf) {
    if (cpf.length < 14) return cpf;
    return '***.${cpf.substring(4, 7)}.***-**';
  }

  double _lerValorTransferencia() {
    final valorText = _controladorValor.text
        .replaceAll('.', '')
        .replaceAll(',', '.');

    return double.tryParse(valorText) ?? 0.0;
  }

  String _gerarDataFormatada(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} às ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }

  void _compartilharComprovante({
    required double valor,
    required String data,
    required String idTransacao,
  }) {
    if (_usuarioDados == null || _usuarioRecebedor == null) return;

    final textoComprovante = '''
Comprovante PIX - PayBank

Transferência realizada com sucesso.

Valor: R\$ ${_formatarMoedaPtBr(valor)}
Pagador: ${_usuarioDados!['nome']}
Recebedor: ${_usuarioRecebedor!['nome']}
CPF do recebedor: ${_mascararCpf(_usuarioRecebedor!['cpf'])}
Instituição: PayBank
Agência: ${_usuarioRecebedor!['agencia']}
Conta: ${_usuarioRecebedor!['numero_conta']}
Data e hora: $data
ID da transação: $idTransacao
''';

    Share.share(textoComprovante);
  }

  Future<void> _validarERevisar() async {
    if (_usuarioDados == null) return;

    final chave = _controladorChave.text.trim();
    final valorTransferencia = _lerValorTransferencia();
    final saldoAtual = (_usuarioDados!['saldo'] as num?)?.toDouble() ?? 0.0;

    if (chave.isEmpty || valorTransferencia <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha a chave e um valor válido.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (valorTransferencia > saldoAtual) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você não tem saldo suficiente para esse PIX!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final bancoDados = DatabaseHelper.instance;

    final recebedor = await bancoDados.buscarUsuarioPorChavePix(
      tipo: _tipoChaveSelecionada,
      chave: chave,
    );

    if (!mounted) return;

    if (recebedor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chave PIX não encontrada ou inativa.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (recebedor['id'] == _usuarioDados!['id']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você não pode fazer um PIX para você mesmo.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _usuarioRecebedor = recebedor;
    });

    _mostrarRevisaoPix(valorTransferencia);
  }

  void _mostrarRevisaoPix(double valorTransferencia) {
    if (_usuarioDados == null || _usuarioRecebedor == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                _linhaRevisao('De', _usuarioDados!['nome']),
                _linhaRevisao('Para', _usuarioRecebedor!['nome']),
                _linhaRevisao(
                  'CPF',
                  _mascararCpf(_usuarioRecebedor!['cpf']),
                ),
                _linhaRevisao(
                  'Conta',
                  'Ag. ${_usuarioRecebedor!['agencia']} | Conta ${_usuarioRecebedor!['numero_conta']}',
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
                      Navigator.pop(context);
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
      builder: (context) {
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final senhaDigitada = _controladorSenhaTransacao.text.trim();
                final senhaCorreta =
                    _usuarioDados?['senha_transacao']?.toString() ?? '';

                if (senhaDigitada.length != 6 || senhaDigitada != senhaCorreta) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Senha de transação incorreta.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                _processarPix(valorTransferencia);
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processarPix(double valorTransferencia) async {
    if (_usuarioDados == null || _usuarioRecebedor == null) return;

    try {
      final bancoDados = DatabaseHelper.instance;
      final banco = await bancoDados.database;

      final saldoRemetente =
          (_usuarioDados!['saldo'] as num?)?.toDouble() ?? 0.0;
      final saldoRecebedor =
          (_usuarioRecebedor!['saldo'] as num?)?.toDouble() ?? 0.0;

      final novoSaldoRemetente = saldoRemetente - valorTransferencia;
      final novoSaldoRecebedor = saldoRecebedor + valorTransferencia;

      await banco.update(
        'usuarios',
        {'saldo': novoSaldoRemetente},
        where: 'id = ?',
        whereArgs: [_usuarioDados!['id']],
      );

      await banco.update(
        'usuarios',
        {'saldo': novoSaldoRecebedor},
        where: 'id = ?',
        whereArgs: [_usuarioRecebedor!['id']],
      );

      final agora = DateTime.now();
      final dataFormatada = _gerarDataFormatada(agora);
      final idTransacao = 'E${agora.millisecondsSinceEpoch}';

      await bancoDados.gravarTransferencia({
        'id_usuario': _usuarioDados!['id'],
        'tipo': 'SAIDA',
        'recebedor': _usuarioRecebedor!['nome'],
        'pagador': _usuarioDados!['nome'],
        'cpf_recebedor': _usuarioRecebedor!['cpf'],
        'agencia_recebedor': _usuarioRecebedor!['agencia'],
        'conta_recebedor': _usuarioRecebedor!['numero_conta'],
        'valor': valorTransferencia,
        'data': dataFormatada,
        'id_transacao': idTransacao,
      });

      await bancoDados.gravarTransferencia({
        'id_usuario': _usuarioRecebedor!['id'],
        'tipo': 'ENTRADA',
        'recebedor': _usuarioDados!['nome'],
        'pagador': _usuarioDados!['nome'],
        'cpf_recebedor': _usuarioRecebedor!['cpf'],
        'agencia_recebedor': _usuarioRecebedor!['agencia'],
        'conta_recebedor': _usuarioRecebedor!['numero_conta'],
        'valor': valorTransferencia,
        'data': dataFormatada,
        'id_transacao': idTransacao,
      });

      if (!mounted) return;

      _mostrarComprovantePix(
        valor: valorTransferencia,
        data: dataFormatada,
        idTransacao: idTransacao,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao processar PIX: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _mostrarComprovantePix({
    required double valor,
    required String data,
    required String idTransacao,
  }) {
    if (_usuarioDados == null || _usuarioRecebedor == null) return;

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
                      _linhaComprovante('Pagador', _usuarioDados!['nome']),
                      const Divider(height: 20),
                      _linhaComprovante('Recebedor', _usuarioRecebedor!['nome']),
                      const Divider(height: 20),
                      _linhaComprovante(
                        'CPF',
                        _mascararCpf(_usuarioRecebedor!['cpf']),
                      ),
                      const Divider(height: 20),
                      _linhaComprovante(
                        'Conta',
                        'Ag. ${_usuarioRecebedor!['agencia']} | ${_usuarioRecebedor!['numero_conta']}',
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
    final saldoAtual =
        _usuarioDados != null ? (_usuarioDados!['saldo'] as num).toDouble() : 0.0;

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
                        'R\$ ${_formatarMoedaPtBr(saldoAtual)}',
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
                onPressed: _validarERevisar,
                child: const Row(
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