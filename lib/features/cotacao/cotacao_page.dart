import 'package:flutter/material.dart';
import '../../services/cotacao_service.dart';

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

  final CotacaoService _cotacaoService = CotacaoService();
  final TextEditingController _controllerConversor = TextEditingController();

  String _moedaAtiva = 'USD';
  double _resultadoConversao = 0.0;
  bool _carregando = true;
  String? _erro;
  DateTime? _ultimaAtualizacao;

  final Map<String, double> _taxas = {
    'USD': 0.0,
    'EUR': 0.0,
    'BTC': 0.0,
  };

  final Map<String, String> _variacoes = {
    'USD': '0.00',
    'EUR': '0.00',
    'BTC': '0.00',
  };

  final Map<String, dynamic> _moedasInfo = {
    'USD': {'nome': 'Dólar Americano', 'icone': '🇺🇸', 'sigla': 'USD'},
    'EUR': {'nome': 'Euro', 'icone': '🇪🇺', 'sigla': 'EUR'},
    'BTC': {'nome': 'Bitcoin', 'icone': '₿', 'sigla': 'BTC'},
  };

  @override
  void initState() {
    super.initState();
    _carregarCotacoes();
  }

  @override
  void dispose() {
    _controllerConversor.dispose();
    super.dispose();
  }

  Future<void> _carregarCotacoes() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final dados = await _cotacaoService.buscarCotacoes();

      setState(() {
        _taxas['USD'] = double.tryParse(dados['USDBRL']['bid']) ?? 0.0;
        _taxas['EUR'] = double.tryParse(dados['EURBRL']['bid']) ?? 0.0;
        _taxas['BTC'] = double.tryParse(dados['BTCBRL']['bid']) ?? 0.0;

        _variacoes['USD'] = dados['USDBRL']['pctChange'] ?? '0.00';
        _variacoes['EUR'] = dados['EURBRL']['pctChange'] ?? '0.00';
        _variacoes['BTC'] = dados['BTCBRL']['pctChange'] ?? '0.00';

        _ultimaAtualizacao = DateTime.now();
        _carregando = false;
      });

      _calcularConversao(_controllerConversor.text);
    } catch (e) {
      setState(() {
        _erro = 'Erro ao buscar cotações. Verifique sua conexão.';
        _carregando = false;
      });
    }
  }

  void _calcularConversao(String valor) {
    String valorLimpo = valor.replaceAll('.', '').replaceAll(',', '.');
    double valorEmReais = double.tryParse(valorLimpo) ?? 0.0;
    double taxa = _taxas[_moedaAtiva] ?? 0.0;

    setState(() {
      if (taxa > 0) {
        _resultadoConversao = valorEmReais / taxa;
      } else {
        _resultadoConversao = 0.0;
      }
    });
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

  String _formatarHora(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');

    return '$dia/$mes às $hora:$minuto';
  }

  bool _subiu(String sigla) {
    final valor = double.tryParse(_variacoes[sigla] ?? '0') ?? 0.0;
    return valor >= 0;
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final titulo = args?['titulo'] ?? 'Cotações';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          titulo,
          style: TextStyle(
            color: greenDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: greenDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: greenPrimary),
            onPressed: _carregando ? null : _carregarCotacoes,
          ),
        ],
      ),
      body: _carregando
          ? Center(
              child: CircularProgressIndicator(color: greenPrimary),
            )
          : _erro != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wifi_off,
                          size: 50,
                          color: greyText,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _erro!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: greyText),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _carregarCotacoes,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: greenPrimary,
                          ),
                          child: const Text(
                            'Tentar novamente',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Converter de Real (R\$) para:',
                        style: TextStyle(color: greyText, fontSize: 12),
                      ),
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
                                });

                                _calcularConversao(
                                  _controllerConversor.text,
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 15),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: ativa ? greenPrimary : greyBackground,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  sigla,
                                  style: TextStyle(
                                    color: ativa ? Colors.white : greenDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 30),

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
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Valor em Reais (R\$)',
                                labelStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                                border: InputBorder.none,
                                prefixText: 'R\$ ',
                                prefixStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Divider(color: Colors.white24),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Equivale a:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FittedBox(
                                    alignment: Alignment.centerRight,
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${_resultadoConversao.toStringAsFixed(4).replaceAll('.', ',')} $_moedaAtiva',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _carregarCotacoes,
                          icon: Icon(Icons.refresh, color: greenPrimary),
                          label: Text(
                            'Atualizar cotação',
                            style: TextStyle(
                              color: greenPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: greenPrimary, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                      if (_ultimaAtualizacao != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Center(
                            child: Text(
                              'Atualizado em ${_formatarHora(_ultimaAtualizacao!)}',
                              style: TextStyle(
                                color: greyText,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 40),

                      Text(
                        'Cotações de Hoje',
                        style: TextStyle(
                          color: greenDark,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildMoedaCard(
                        'Dólar Americano',
                        'USD',
                        'R\$ ${_formatarMoedaPtBr(_taxas['USD'] ?? 0)}',
                        '${_variacoes['USD']}%',
                        _subiu('USD'),
                      ),
                      _buildMoedaCard(
                        'Euro',
                        'EUR',
                        'R\$ ${_formatarMoedaPtBr(_taxas['EUR'] ?? 0)}',
                        '${_variacoes['EUR']}%',
                        _subiu('EUR'),
                      ),
                      _buildMoedaCard(
                        'Bitcoin',
                        'BTC',
                        'R\$ ${_formatarMoedaPtBr(_taxas['BTC'] ?? 0)}',
                        '${_variacoes['BTC']}%',
                        _subiu('BTC'),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMoedaCard(
    String nome,
    String sigla,
    String valor,
    String variacao,
    bool subiu,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: greyBackground,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  sigla == 'BTC' ? '₿' : '\$',
                  style: TextStyle(
                    color: greenPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: TextStyle(
                      color: greenDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        sigla,
                        style: TextStyle(color: greyText),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        variacao,
                        style: TextStyle(
                          color: subiu ? greenPrimary : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Text(
            valor,
            style: TextStyle(
              color: greenDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}