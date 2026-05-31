import 'package:flutter/material.dart';

class CotacaoPage extends StatefulWidget {
  const CotacaoPage({super.key});

  @override
  State<CotacaoPage> createState() => _CotacaoPageState();
}

class _CotacaoPageState extends State<CotacaoPage> {
  final Color greenPrimary = const Color(0xFF1DB954);
  final Color greenDark = const Color(0xFF191414);
  final Color greyBackground = const Color(0xFFF8F9FA);
  final Color greyText = const Color(0xFF6C757D);

  String _moedaAtiva = 'USD';
  final TextEditingController _controllerConversor = TextEditingController();
  double _resultadoConversao = 0.0;

  final Map<String, double> _taxas = {
    'USD': 5.24,
    'EUR': 5.68,
    'BTC': 342150.0,
    'ETH': 18450.0,
  };

  final Map<String, dynamic> _moedasInfo = {
    'USD': {'nome': 'Dólar Americano', 'icone': '🇺🇸', 'sigla': 'USD'},
    'EUR': {'nome': 'Euro', 'icone': '🇪🇺', 'sigla': 'EUR'},
    'BTC': {'nome': 'Bitcoin', 'icone': '₿', 'sigla': 'BTC'},
    'ETH': {'nome': 'Ethereum', 'icone': '🔷', 'sigla': 'ETH'},
  };

  void _calcularConversao(String valor) {
    // Agora aceita tanto ponto quanto vírgula e remove formatadores visuais
    String valorLimpo = valor.replaceAll('.', '').replaceAll(',', '.');
    double valorEmReais = double.tryParse(valorLimpo) ?? 0.0;
    setState(() {
      _resultadoConversao = valorEmReais / (_taxas[_moedaAtiva] ?? 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Cotações', style: TextStyle(color: greenDark, fontWeight: FontWeight.bold)),
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
            Text('Converter de Real (R\$) para:', style: TextStyle(color: greyText, fontSize: 12)),
            const SizedBox(height: 15),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _moedasInfo.keys.map((String sigla) {
                  bool ativa = _moedaAtiva == sigla;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _moedaAtiva = sigla;
                        _calcularConversao(_controllerConversor.text);
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 15),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: ativa ? greenPrimary : greyBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(sigla, style: TextStyle(color: ativa ? Colors.white : greenDark, fontWeight: FontWeight.bold)),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 30),

            // --- CONVERSOR ADAPTADO ---
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: greenPrimary, 
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _controllerConversor,
                    onChanged: _calcularConversao,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Valor em Reais (R\$)',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                      border: InputBorder.none,
                      prefixText: 'R\$ ',
                      prefixStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Equivale a:', style: TextStyle(color: Colors.white, fontSize: 16)),
                      const SizedBox(width: 10),
                      // Correção do OVERFLOW: O FittedBox encolhe o texto se for muito grande
                      Expanded(
                        child: FittedBox(
                          alignment: Alignment.centerRight,
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${_resultadoConversao.toStringAsFixed(2).replaceAll('.', ',')} $_moedaAtiva',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            Text('Cotações de Hoje', style: TextStyle(color: greenDark, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildMoedaCard('Dólar Americano', 'USD', 'R\$ 5,24', '+0.45%', true),
            _buildMoedaCard('Euro', 'EUR', 'R\$ 5,68', '-0.12%', false),
            _buildMoedaCard('Bitcoin', 'BTC', 'R\$ 342.150,00', '+2.81%', true),
            _buildMoedaCard('Ethereum', 'ETH', 'R\$ 18.450,00', '+1.15%', true),
          ],
        ),
      ),
    );
  }

  Widget _buildMoedaCard(String nome, String sigla, String valor, String variacao, bool subiu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!, width: 2)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: greyBackground, shape: BoxShape.circle), child: Text(sigla == 'BTC' || sigla == 'ETH' ? '₿' : '\$', style: TextStyle(color: greenPrimary, fontSize: 20, fontWeight: FontWeight.bold))),
            const SizedBox(width: 15),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(nome, style: TextStyle(color: greenDark, fontWeight: FontWeight.bold)), Text(sigla, style: TextStyle(color: greyText))]),
          ]),
          Text(valor, style: TextStyle(color: greenDark, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}