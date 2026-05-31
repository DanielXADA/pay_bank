import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../database/db_helper.dart';

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({super.key});

  @override
  State<PrincipalPage> createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> {
  Map<String, dynamic>? _usuarioDados;
  List<Map<String, dynamic>> _listaTransferencias = [];
  final _controladorDeposito = TextEditingController();
  bool _carregando = true;
  bool _saldoVisivel = true;

  final Color greenPrimary = const Color(0xFF1DB954);
  final Color greenDark = const Color(0xFF191414);
  final Color greyBackground = const Color(0xFFF8F9FA);
  final Color greyText = const Color(0xFF6C757D);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_usuarioDados == null) {
      final dadosIniciais =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (dadosIniciais != null) {
        _carregarDadosReal(dadosIniciais['nome_usuario']);
      }
    }
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
    if (cpf == null || cpf.length < 14) return 'Não informado';
    return '***.${cpf.substring(4, 7)}.***-**';
  }

  Future<void> _carregarDadosReal(String nomeUsuario) async {
    final bancoDados = DatabaseHelper.instance;
    final usuarioAtualizado =
        await bancoDados.buscarUsuarioPorLogin(nomeUsuario);

    if (usuarioAtualizado != null) {
      final transferencias =
          await bancoDados.buscarTransferenciasDoUsuario(usuarioAtualizado['id']);

      if (mounted) {
        setState(() {
          _usuarioDados = usuarioAtualizado;
          _listaTransferencias = transferencias;
          _carregando = false;
        });
      }
    }
  }

  Widget _fotoPerfilHome() {
    final caminhoFoto = _usuarioDados?['foto_rosto'];

    if (caminhoFoto != null && caminhoFoto.toString().isNotEmpty) {
      final arquivo = File(caminhoFoto);

      if (arquivo.existsSync()) {
        return CircleAvatar(radius: 18, backgroundImage: FileImage(arquivo));
      }
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFFDEE2E6),
      child: Icon(Icons.person, color: greenDark, size: 20),
    );
  }

  void _mostrarCaixaDeposito() {
    _controladorDeposito.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
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
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: greenPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: greenPrimary,
                    size: 35,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Qual valor deseja depositar?',
                  style: TextStyle(
                    color: greenDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: IntrinsicWidth(
                    child: TextField(
                      controller: _controladorDeposito,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [CentavosInputFormatter()],
                      autofocus: true,
                      style: TextStyle(
                        color: greenPrimary,
                        fontSize: 45,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        prefixText: 'R\$ ',
                        prefixStyle: TextStyle(
                          color: greenPrimary,
                          fontSize: 45,
                          fontWeight: FontWeight.bold,
                        ),
                        border: InputBorder.none,
                        hintText: '0,00',
                        hintStyle: TextStyle(color: Colors.grey[300]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
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
                    onPressed: () async {
                      final textoValor = _controladorDeposito.text
                          .replaceAll('.', '')
                          .replaceAll(',', '.');

                      final valorDeposito = double.tryParse(textoValor);

                      if (valorDeposito != null &&
                          valorDeposito > 0 &&
                          _usuarioDados != null) {
                        final bancoDados = DatabaseHelper.instance;
                        final banco = await bancoDados.database;

                        final saldoAntigo =
                            (_usuarioDados!['saldo'] as num?)?.toDouble() ??
                                0.0;

                        final agora = DateTime.now();

                        await banco.insert('transferencias', {
                          'id_usuario': _usuarioDados!['id'],
                          'tipo': 'ENTRADA',
                          'recebedor': 'Depósito em Conta',
                          'pagador': _usuarioDados!['nome'],
                          'valor': valorDeposito,
                          'data': agora.toString().substring(0, 19),
                          'id_transacao': 'D${agora.millisecondsSinceEpoch}',
                        });

                        await banco.update(
                          'usuarios',
                          {'saldo': saldoAntigo + valorDeposito},
                          where: 'id = ?',
                          whereArgs: [_usuarioDados!['id']],
                        );

                        _carregarDadosReal(_usuarioDados!['nome_usuario']);

                        if (context.mounted) {
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 10),
                                  Text(
                                    'Depósito realizado com sucesso!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: greenPrimary,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text(
                      'Confirmar Depósito',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
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

  void _compartilharComprovanteHistorico(Map<String, dynamic> transferencia) {
    final valorFormatado =
        _formatarMoedaPtBr((transferencia['valor'] as num).toDouble());

    final ehEntrada = transferencia['tipo'] == 'ENTRADA';
    final ehDeposito = transferencia['recebedor'] == 'Depósito em Conta';

    final texto = '''
Comprovante PayBank

Tipo: ${ehDeposito ? 'Depósito' : (ehEntrada ? 'PIX Recebido' : 'PIX Enviado')}
Valor: R\$ $valorFormatado
${ehDeposito ? 'Conta destino' : (ehEntrada ? 'Pagador' : 'Recebedor')}: ${transferencia['recebedor']}
CPF: ${_mascararCpf(transferencia['cpf_recebedor']?.toString())}
Data: ${transferencia['data']}
ID: ${transferencia['id_transacao'] ?? 'Não informado'}
''';

    Share.share(texto);
  }

  void _mostrarComprovanteAntigo(Map<String, dynamic> transferencia) {
    final valorFormatado =
        _formatarMoedaPtBr((transferencia['valor'] as num).toDouble());

    final ehEntrada = transferencia['tipo'] == 'ENTRADA';
    final ehDeposito = transferencia['recebedor'] == 'Depósito em Conta';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            ehDeposito ? 'Comprovante de Depósito' : 'Comprovante de PIX',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Icon(
                    Icons.check_circle,
                    size: 50,
                    color: greenPrimary,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Valor: R\$ $valorFormatado',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                Text(
                  ehDeposito
                      ? 'Conta Destino: Digital PayBank'
                      : (ehEntrada
                          ? 'Pagador: ${transferencia['recebedor']}'
                          : 'Recebedor: ${transferencia['recebedor']}'),
                ),
                const SizedBox(height: 5),
                if (transferencia['cpf_recebedor'] != null)
                  Text(
                    'CPF: ${_mascararCpf(transferencia['cpf_recebedor']?.toString())}',
                  ),
                if (transferencia['agencia_recebedor'] != null &&
                    transferencia['conta_recebedor'] != null)
                  Text(
                    'Conta: Ag. ${transferencia['agencia_recebedor']} | ${transferencia['conta_recebedor']}',
                  ),
                const SizedBox(height: 5),
                Text('Data: ${transferencia['data']}'),
                const SizedBox(height: 5),
                Text(
                  'ID: ${transferencia['id_transacao'] ?? 'Não informado'}',
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => _compartilharComprovanteHistorico(transferencia),
              icon: Icon(Icons.share, color: greenPrimary),
              label: Text(
                'Compartilhar',
                style: TextStyle(color: greenPrimary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Fechar', style: TextStyle(color: greyText)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transferencia) {
    final valorFormatadoItem =
        _formatarMoedaPtBr((transferencia['valor'] as num).toDouble());

    final ehEntrada = transferencia['tipo'] == 'ENTRADA';
    final ehDeposito = transferencia['recebedor'] == 'Depósito em Conta';

    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: InkWell(
        onTap: () => _mostrarComprovanteAntigo(transferencia),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: greyBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  ehDeposito
                      ? Icons.account_balance_wallet
                      : (ehEntrada ? Icons.arrow_downward : Icons.arrow_upward),
                  color: ehDeposito
                      ? Colors.blue
                      : (ehEntrada ? greenPrimary : Colors.red),
                  size: 20,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ehDeposito
                          ? 'Depósito'
                          : (ehEntrada ? 'PIX Recebido' : 'PIX Enviado'),
                      style: TextStyle(
                        color: greenDark,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ehDeposito ? 'Conta PayBank' : transferencia['recebedor'],
                      style: TextStyle(color: greyText, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${ehEntrada ? "+" : "-"} R\$ $valorFormatadoItem',
                    style: TextStyle(
                      color: ehDeposito
                          ? Colors.blue
                          : (ehEntrada ? greenPrimary : Colors.red),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transferencia['data'].toString().length >= 10
                        ? transferencia['data'].toString().substring(0, 10)
                        : transferencia['data'].toString(),
                    style: TextStyle(color: greyText, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controladorDeposito.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando || _usuarioDados == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: greenPrimary),
        ),
      );
    }

    final saldoObtido = (_usuarioDados!['saldo'] as num?)?.toDouble() ?? 0.0;
    final saldoFormatado = _formatarMoedaPtBr(saldoObtido);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: _fotoPerfilHome(),
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/perfil',
              arguments: _usuarioDados,
            ).then((_) {
              _carregarDadosReal(_usuarioDados!['nome_usuario']);
            });
          },
        ),
        title: Text(
          'Olá, ${_usuarioDados!['nome'].split(' ')[0]}',
          style: TextStyle(
            color: greenDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app, color: greyText),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 10.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: greenPrimary.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 30,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: greenPrimary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Saldo Disponível',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'R\$ ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _saldoVisivel ? saldoFormatado : '••••••',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _saldoVisivel = !_saldoVisivel;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _saldoVisivel
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _saldoVisivel ? 'Ocultar' : 'Mostrar',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionItem(
                          Icons.account_balance_wallet,
                          'Depositar',
                          _mostrarCaixaDeposito,
                        ),
                        _buildActionItem(Icons.pix, 'Transferir', () {
                          Navigator.pushNamed(
                            context,
                            '/transferencia',
                            arguments: _usuarioDados,
                          ).then((_) {
                            _carregarDadosReal(
                              _usuarioDados!['nome_usuario'],
                            );
                          });
                        }),
                        _buildActionItem(
                          Icons.monetization_on,
                          'Cotações',
                          () => Navigator.pushNamed(
                            context,
                            '/cotacao',
                            arguments: {
                              'titulo': 'Cotações',
                              'moedaInicial': 'USD',
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Últimas Transações',
                  style: TextStyle(
                    color: greenDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExtratoCompletoPage(
                          transferencias: _listaTransferencias,
                          buildItemFunction: _buildTransactionItem,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Ver Tudo',
                    style: TextStyle(
                      color: greyText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_listaTransferencias.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30.0),
                  child: Text(
                    'Nenhuma transferência ainda.',
                    style: TextStyle(color: greyText),
                  ),
                ),
              )
            else
              ..._listaTransferencias.take(4).map((t) => _buildTransactionItem(t)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: greyBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: greenDark, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: greyText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

class ExtratoCompletoPage extends StatelessWidget {
  final List<Map<String, dynamic>> transferencias;
  final Widget Function(Map<String, dynamic>) buildItemFunction;

  const ExtratoCompletoPage({
    super.key,
    required this.transferencias,
    required this.buildItemFunction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Todo o Extrato',
          style: TextStyle(
            color: Color(0xFF191414),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF191414)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: transferencias.isEmpty
          ? const Center(
              child: Text(
                'Você ainda não possui transações.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: transferencias.length,
              itemBuilder: (context, index) {
                return buildItemFunction(transferencias[index]);
              },
            ),
    );
  }
}