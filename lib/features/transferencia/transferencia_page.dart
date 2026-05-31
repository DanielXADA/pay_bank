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
  final _controladorChave = TextEditingController();
  final _controladorValor = TextEditingController();
  String _tipoChaveSelecionada = 'CPF'; 

  final Color greenPrimary = const Color(0xFF1DB954);
  final Color greenDark = const Color(0xFF191414);
  final Color greyBackground = const Color(0xFFF8F9FA);
  final Color greyText = const Color(0xFF6C757D);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_usuarioDados == null) {
      _usuarioDados = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    }
  }

  // --- MÁSCARAS E TECLADOS ---
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

  void _compartilharComprovante(String recebedor, String valor, String data) {
    final textoComprovante = '''
✅ Transferência PIX - PayBank

Valor: R\$ $valor
Para: $recebedor
Data: $data

Comprovante gerado pelo aplicativo PayBank.
''';
    Share.share(textoComprovante);
  }

  void _mostrarComprovantePix(String recebedor, String valor, String data) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: greenPrimary.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.check_circle, size: 60, color: greenPrimary),
              ),
              const SizedBox(height: 20),
              const Text('PIX Enviado!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('R\$ $valor', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: greenPrimary)),
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: greyBackground, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Para:', style: TextStyle(color: greyText)),
                        Text(recebedor, style: TextStyle(fontWeight: FontWeight.bold, color: greenDark)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Data:', style: TextStyle(color: greyText)),
                        Text(data, style: TextStyle(fontWeight: FontWeight.bold, color: greenDark)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton.icon(
              onPressed: () => _compartilharComprovante(recebedor, valor, data),
              icon: Icon(Icons.share, color: greenPrimary),
              label: Text('Compartilhar', style: TextStyle(color: greenPrimary, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: greenDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context); 
                Navigator.pop(context); 
              },
              child: const Text('Fechar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final saldoAtual = _usuarioDados != null ? (_usuarioDados!['saldo'] as num).toDouble() : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Área PIX', style: TextStyle(color: greenDark, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: greenDark), onPressed: () => Navigator.pop(context)),
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
                boxShadow: [BoxShadow(color: greenPrimary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Saldo disponível para envio', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 5),
                      Text('R\$ ${_formatarMoedaPtBr(saldoAtual)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.account_balance_wallet, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 35),
            Text('1. Qual é o tipo de chave?', style: TextStyle(color: greenDark, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['CPF', 'Celular', 'E-mail', 'Aleatória'].map((tipo) {
                  bool ativo = _tipoChaveSelecionada == tipo;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: ChoiceChip(
                      label: Text(tipo, style: TextStyle(color: ativo ? Colors.white : greenDark, fontWeight: FontWeight.bold)),
                      selected: ativo,
                      selectedColor: greenPrimary,
                      backgroundColor: greyBackground,
                      elevation: 0,
                      pressElevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: ativo ? greenPrimary : Colors.grey[300]!), 
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
            Text('2. Insira os dados', style: TextStyle(color: greenDark, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            TextField(
              controller: _controladorChave,
              keyboardType: _obterTecladoPorTipo(),
              inputFormatters: [_obterMascaraPorTipo()],
              style: TextStyle(color: greenDark, fontSize: 16, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Chave $_tipoChaveSelecionada',
                labelStyle: TextStyle(color: greyText),
                hintText: _tipoChaveSelecionada == 'CPF' ? '000.000.000-00' : (_tipoChaveSelecionada == 'Celular' ? '(00) 00000-0000' : 'Digite aqui...'),
                prefixIcon: Icon(Icons.vpn_key_rounded, color: greenPrimary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: greenPrimary, width: 2.0)),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // CAMPO VALOR: Com formatador de centavos automático
            TextField(
              controller: _controladorValor,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [CentavosInputFormatter()], // Formatação em tempo real
              style: TextStyle(color: greenPrimary, fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Valor da Transferência',
                labelStyle: TextStyle(color: greyText, fontSize: 14),
                prefixText: 'R\$ ',
                prefixStyle: TextStyle(color: greenPrimary, fontSize: 24, fontWeight: FontWeight.bold),
                prefixIcon: Icon(Icons.attach_money_rounded, color: greenPrimary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: greenPrimary, width: 2.0)),
              ),
            ),
            
            const SizedBox(height: 50),
            
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: greenPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () async {
                  final chave = _controladorChave.text.trim();
                  // Transforma "1.500,00" em "1500.00" para o banco de dados
                  final valorText = _controladorValor.text.replaceAll('.', '').replaceAll(',', '.');
                  final valorTransferencia = double.tryParse(valorText);

                  if (chave.isEmpty || valorTransferencia == null || valorTransferencia <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, preencha a chave e um valor válido.'), backgroundColor: Colors.redAccent));
                    return;
                  }

                  if (valorTransferencia > saldoAtual) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Você não tem saldo suficiente para esse PIX!'), backgroundColor: Colors.redAccent));
                    return;
                  }

                  final bancoDados = DatabaseHelper.instance;
                  final db = await bancoDados.database;
                  final novoSaldo = saldoAtual - valorTransferencia;
                  await db.update('usuarios', {'saldo': novoSaldo}, where: 'id = ?', whereArgs: [_usuarioDados!['id']]);

                  final dataTransacao = DateTime.now().toString().substring(0, 16); 

                  await db.insert('transferencias', {
                    'id_usuario': _usuarioDados!['id'],
                    'tipo': 'SAIDA',
                    'recebedor': chave,
                    'valor': valorTransferencia,
                    'data': dataTransacao,
                  });

                  if (mounted) {
                    final valorFormatado = _formatarMoedaPtBr(valorTransferencia);
                    _mostrarComprovantePix(chave, valorFormatado, dataTransacao);
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Enviar PIX', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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

// Classe que formata o dinheiro automaticamente (ex: "100" vira "1,00")
class CentavosInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    double value = double.parse(digitsOnly) / 100;
    String newText = value.toStringAsFixed(2).replaceAll('.', ',');
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    newText = newText.replaceAllMapped(reg, (Match match) => '${match[1]}.');
    return newValue.copyWith(text: newText, selection: TextSelection.collapsed(offset: newText.length));
  }
}