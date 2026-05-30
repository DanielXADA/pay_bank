import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _usuarioDados = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Enviar PIX'), backgroundColor: greenPrimary),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selecione o tipo de chave:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['CPF', 'Celular', 'E-mail', 'Aleatória'].map((tipo) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(tipo),
                      selected: _tipoChaveSelecionada == tipo,
                      onSelected: (val) => setState(() => _tipoChaveSelecionada = tipo),
                      selectedColor: greenPrimary,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 25),
            Row(children: [Icon(Icons.vpn_key, color: greenPrimary), const SizedBox(width: 8), Text('Chave PIX', style: TextStyle(color: greenPrimary, fontWeight: FontWeight.bold))]),
            TextField(controller: _controladorChave, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[400]!)))),
            const SizedBox(height: 20),
            Row(children: [Icon(Icons.monetization_on, color: greenPrimary), const SizedBox(width: 8), Text('Valor a transferir', style: TextStyle(color: greenPrimary, fontWeight: FontWeight.bold))]),
            TextField(controller: _controladorValor, keyboardType: TextInputType.number, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[400]!)))),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: greenPrimary),
                onPressed: () async {
                  final valor = double.tryParse(_controladorValor.text.replaceAll(',', '.'));
                  if (valor != null && valor > 0 && _usuarioDados != null && (_usuarioDados!['saldo'] as num) >= valor) {
                    final db = await DatabaseHelper.instance.database;
                    await db.update('usuarios', {'saldo': (_usuarioDados!['saldo'] as num) - valor}, where: 'id = ?', whereArgs: [_usuarioDados!['id']]);
                    await db.insert('transferencias', {'id_usuario': _usuarioDados!['id'], 'tipo': 'SAIDA', 'recebedor': _controladorChave.text, 'valor': valor, 'data': DateTime.now().toString().substring(0,16)});
                    if(mounted) Navigator.pop(context); // Volta após sucesso
                  }
                },
                child: const Text('Confirmar Transferência', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}