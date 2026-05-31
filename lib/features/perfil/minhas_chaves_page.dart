import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  final List<Map<String, dynamic>> _chaves = [];
  bool _inicializado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inicializado) {
      final usuarioDados = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
      if (usuarioDados['cpf'] != null) _chaves.add({'tipo': 'CPF', 'valor': usuarioDados['cpf'], 'icone': Icons.badge});
      if (usuarioDados['telefone'] != null) _chaves.add({'tipo': 'Celular', 'valor': usuarioDados['telefone'], 'icone': Icons.phone_android});
      if (usuarioDados['email'] != null) _chaves.add({'tipo': 'E-mail', 'valor': usuarioDados['email'], 'icone': Icons.email});
      _inicializado = true;
    }
  }

  void _excluirChave(int index) {
    setState(() {
      _chaves.removeAt(index);
    });
  }

  String _gerarChaveAleatoria() {
    final r = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(32, (index) {
      if (index == 8 || index == 12 || index == 16 || index == 20) return '-';
      return chars[r.nextInt(chars.length)];
    }).join('');
  }

  TextInputFormatter _obterMascara(String tipo) {
    if (tipo == 'CPF') {
      return TextInputFormatter.withFunction((oldValue, newValue) {
        final text = newValue.text.replaceAll(RegExp(r'\D'), '');
        if (text.length > 11) return oldValue;
        String formatted = '';
        for (int i = 0; i < text.length; i++) {
          if (i == 3 || i == 6) formatted += '.';
          if (i == 9) formatted += '-';
          formatted += text[i];
        }
        return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
      });
    } else if (tipo == 'Celular') {
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
        return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
      });
    }
    return TextInputFormatter.withFunction((oldValue, newValue) => newValue);
  }

  TextInputType _obterTeclado(String tipo) {
    if (tipo == 'CPF' || tipo == 'Celular') return TextInputType.number;
    if (tipo == 'E-mail') return TextInputType.emailAddress;
    return TextInputType.text;
  }

  IconData _obterIcone(String tipo) {
    if (tipo == 'CPF') return Icons.badge;
    if (tipo == 'Celular') return Icons.phone_android;
    if (tipo == 'E-mail') return Icons.email;
    return Icons.vpn_key;
  }

  void _mostrarModalCadastro() {
    String tipoSelecionado = 'CPF';
    final TextEditingController controlador = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 25),
                    Text('Cadastrar Nova Chave', style: TextStyle(color: greenDark, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: ['CPF', 'Celular', 'E-mail', 'Aleatória'].map((tipo) {
                        bool ativo = tipoSelecionado == tipo;
                        return ChoiceChip(
                          label: Text(tipo, style: TextStyle(color: ativo ? Colors.white : greenDark, fontWeight: FontWeight.bold)),
                          selected: ativo,
                          selectedColor: greenPrimary,
                          backgroundColor: greyBackground,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: ativo ? greenPrimary : Colors.grey[300]!)),
                          onSelected: (val) {
                            setModalState(() {
                              tipoSelecionado = tipo;
                              controlador.text = tipo == 'Aleatória' ? _gerarChaveAleatoria() : '';
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 25),
                    TextField(
                      controller: controlador,
                      keyboardType: _obterTeclado(tipoSelecionado),
                      inputFormatters: [_obterMascara(tipoSelecionado)],
                      readOnly: tipoSelecionado == 'Aleatória',
                      style: TextStyle(color: greenDark, fontSize: 16, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Chave $tipoSelecionado',
                        labelStyle: TextStyle(color: greyText),
                        prefixIcon: Icon(_obterIcone(tipoSelecionado), color: greenPrimary),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: greenPrimary, width: 2.0)),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: greenPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                        onPressed: () {
                          if (controlador.text.trim().isNotEmpty) {
                            setState(() {
                              _chaves.add({'tipo': tipoSelecionado, 'valor': controlador.text.trim(), 'icone': _obterIcone(tipoSelecionado)});
                            });
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Confirmar Cadastro', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Minhas Chaves PIX', style: TextStyle(color: greenDark, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: greenDark), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chaves Cadastradas', style: TextStyle(color: greenDark, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            if (_chaves.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text('Nenhuma chave cadastrada.', style: TextStyle(color: greyText))),
            ..._chaves.asMap().entries.map((entry) {
              int idx = entry.key;
              Map<String, dynamic> chave = entry.value;
              return _buildKeyCard(chave['icone'], chave['tipo'], chave['valor'], idx);
            }),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(side: BorderSide(color: greenPrimary, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                icon: Icon(Icons.add, color: greenPrimary),
                label: Text('Cadastrar Nova Chave', style: TextStyle(color: greenPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: _mostrarModalCadastro,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyCard(IconData icon, String type, String value, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: greyBackground, width: 2)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: greenPrimary.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: greenPrimary)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: TextStyle(color: greyText, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(color: greenDark, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _excluirChave(index)),
        ],
      ),
    );
  }
}