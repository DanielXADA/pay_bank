import 'dart:io';
import 'package:flutter/material.dart';
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
  int _selectedIndex = 0;

  final Color greenPrimary = const Color(0xFF1DB954);
  final Color greenDark = const Color(0xFF191414);
  final Color greyBackground = const Color(0xFFF8F9FA);
  final Color greyText = const Color(0xFF6C757D);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_usuarioDados == null) {
      final dadosIniciais = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
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

  Future<void> _carregarDadosReal(String nomeUsuario) async {
    final bancoDados = DatabaseHelper.instance;
    final usuarioAtualizado = await bancoDados.buscarUsuarioPorLogin(nomeUsuario);
    if (usuarioAtualizado != null) {
      final transferencias = await bancoDados.buscarTransferenciasDoUsuario(usuarioAtualizado['id']);
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
        return CircleAvatar(radius: 20, backgroundImage: FileImage(arquivo));
      }
    }
    return CircleAvatar(radius: 20, backgroundColor: const Color(0xFFDEE2E6), child: Icon(Icons.person, color: greenDark));
  }

  void _mostrarCaixaDeposito() {
    _controladorDeposito.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 25),
                Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: greenPrimary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.account_balance_wallet_outlined, color: greenPrimary, size: 35)),
                const SizedBox(height: 20),
                Text('Qual valor deseja depositar?', style: TextStyle(color: greenDark, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                Center(
                  child: IntrinsicWidth(
                    child: TextField(
                      controller: _controladorDeposito,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      style: TextStyle(color: greenPrimary, fontSize: 45, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(prefixText: 'R\$ ', prefixStyle: TextStyle(color: greenPrimary.withOpacity(0.5), fontSize: 45, fontWeight: FontWeight.bold), border: InputBorder.none, hintText: '0,00', hintStyle: TextStyle(color: Colors.grey[300])),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: greenPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                    onPressed: () async {
                      final textoValor = _controladorDeposito.text.replaceAll(',', '.');
                      final valorDeposito = double.tryParse(textoValor);
                      if (valorDeposito != null && valorDeposito > 0 && _usuarioDados != null) {
                        final bancoDados = DatabaseHelper.instance;
                        final banco = await bancoDados.database;
                        final saldoAntigo = (_usuarioDados!['saldo'] as num?)?.toDouble() ?? 0.0;
                        await banco.insert('transferencias', {
                          'id_usuario': _usuarioDados!['id'],
                          'tipo': 'ENTRADA',
                          'recebedor': 'Depósito em Conta', 
                          'valor': valorDeposito,
                          'data': DateTime.now().toString().substring(0, 19),
                        });
                        await banco.update('usuarios', {'saldo': saldoAntigo + valorDeposito}, where: 'id = ?', whereArgs: [_usuarioDados!['id']]);
                        _carregarDadosReal(_usuarioDados!['nome_usuario']);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    child: const Text('Confirmar Depósito', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarComprovanteAntigo(Map<String, dynamic> transferencia) {
    final valorFormatado = _formatarMoedaPtBr((transferencia['valor'] as num).toDouble());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(transferencia['recebedor'] == 'Depósito em Conta' ? 'Comprovante de Depósito' : 'Comprovante de PIX'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check_circle, size: 50, color: greenPrimary),
            Text('R\$ $valorFormatado', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando || _usuarioDados == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(_usuarioDados!['nome']),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(_formatarMoedaPtBr((_usuarioDados!['saldo'] as num).toDouble()), _usuarioDados!['agencia'] ?? '0001', _usuarioDados!['numero_conta'] ?? '00000-0'),
            const SizedBox(height: 25),
            _buildQuickActions(),
            const SizedBox(height: 25), 
            _buildRecentTransactionsSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar(String nome) {
    return AppBar(backgroundColor: Colors.white, elevation: 0, leading: Padding(padding: const EdgeInsets.all(8.0), child: _fotoPerfilHome()), title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Bem-vindo', style: TextStyle(color: greyText, fontSize: 12)), Text(nome, style: TextStyle(color: greenDark, fontSize: 16, fontWeight: FontWeight.bold))]), actions: [IconButton(icon: Icon(Icons.exit_to_app, color: greyText), onPressed: () => Navigator.pushReplacementNamed(context, '/login'))]);
  }

  Widget _buildBalanceCard(String saldo, String ag, String cc) {
    return Container(
      width: double.infinity,
      height: 210,
      decoration: BoxDecoration(gradient: LinearGradient(colors: [greenPrimary, const Color(0xFF1AA34A)]), borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Saldo Disponível', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Row(children: [
                      Expanded(child: FittedBox(alignment: Alignment.centerLeft, fit: BoxFit.scaleDown, child: Text(_saldoVisivel ? 'R\$ $saldo' : 'R\$ •••••', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)))),
                      IconButton(icon: Icon(_saldoVisivel ? Icons.visibility : Icons.visibility_off, color: Colors.white70), onPressed: () => setState(() => _saldoVisivel = !_saldoVisivel))
                    ]),
                  ],
                ),
              ),
              Icon(Icons.account_balance, color: Colors.white.withOpacity(0.5), size: 40),
            ],
          ),
          Text('Ag: $ag   Cc: $cc', style: const TextStyle(color: Colors.white, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton(Icons.account_balance_wallet_outlined, 'Depositar', _mostrarCaixaDeposito),
        _buildActionButton(Icons.pix, 'Pix', () => Navigator.pushNamed(context, '/transferencia', arguments: _usuarioDados).then((_) => _carregarDadosReal(_usuarioDados!['nome_usuario']))),
        _buildActionButton(Icons.monetization_on_outlined, 'Cotações', () => Navigator.pushNamed(context, '/cotacao')),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(child: GestureDetector(onTap: onTap, child: Column(children: [Container(width: 70, height: 70, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: greenPrimary.withOpacity(0.5), width: 1.5)), child: Center(child: Icon(icon, color: greenPrimary, size: 30))), const SizedBox(height: 10), Text(label, style: TextStyle(color: greenDark, fontSize: 14, fontWeight: FontWeight.w500))])));
  }

  Widget _buildRecentTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Histórico de Transações', style: TextStyle(color: greenDark, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ..._listaTransferencias.map((t) {
          final valor = _formatarMoedaPtBr((t['valor'] as num).toDouble());
          final entrada = t['tipo'] == 'ENTRADA';
          final deposito = t['recebedor'] == 'Depósito em Conta';
          return ListTile(
            onTap: () => _mostrarComprovanteAntigo(t),
            leading: Icon(deposito ? Icons.account_balance_wallet : (entrada ? Icons.arrow_downward : Icons.arrow_upward), color: deposito ? Colors.blue : (entrada ? greenPrimary : Colors.red)),
            title: Text(deposito ? 'Depósito' : (entrada ? 'PIX Recebido' : 'PIX Enviado')),
            subtitle: Text(t['data']),
            trailing: Text('${entrada ? "+" : "-"} R\$ $valor', style: TextStyle(fontWeight: FontWeight.bold, color: deposito ? Colors.blue : (entrada ? greenPrimary : Colors.red))),
          );
        }),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      selectedItemColor: greenPrimary,
      onTap: (index) => setState(() => _selectedIndex = index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Estatísticas'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Extrato'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Conta'),
      ],
    );
  }
}