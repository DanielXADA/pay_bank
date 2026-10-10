import 'package:flutter/material.dart';
import '../../domain/entities/currency_quote.dart';
import '../../presentation/viewmodels/quotation_viewmodel.dart';

/// View puramente declarativa no padrão MVVM.
///
/// Não realiza chamadas HTTP, parse de JSON ou regras de conversão cambial.
/// Observa o [QuotationViewModel] conectado à Anti-Corruption Layer do repositório.
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

  late final QuotationViewModel _viewModel;
  final TextEditingController _controllerConversor = TextEditingController();

  final Map<String, dynamic> _moedasInfo = {
    'USD': {'nome': 'Dólar Americano', 'icone': '🇺🇸', 'sigla': 'USD'},
    'EUR': {'nome': 'Euro', 'icone': '🇪🇺', 'sigla': 'EUR'},
    'BTC': {'nome': 'Bitcoin', 'icone': '₿', 'sigla': 'BTC'},
  };

  @override
  void initState() {
    super.initState();
    _viewModel = QuotationViewModel();
    _viewModel.loadQuotes();
  }

  @override
  void dispose() {
    _controllerConversor.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _onConverterChanged(String valor) {
    final valorLimpo = valor.replaceAll('.', '').replaceAll(',', '.');
    final valorEmReais = double.tryParse(valorLimpo) ?? 0.0;
    _viewModel.calculateConversion(valorEmReais);
  }

  String _formatarMoedaPtBr(double valor) {
    final valorFixo = valor.toStringAsFixed(2);
    final partes = valorFixo.split('.');
    final inteira = partes[0];
    final decimal = partes[1];

    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final inteiraFormatada = inteira.replaceAllMapped(reg, (Match match) => '${match[1]}.');

    return '$inteiraFormatada,$decimal';
  }

  String _formatarHora(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');

    return '$dia/$mes às $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final titulo = args?['titulo'] ?? 'Cotações';

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
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
                onPressed: _viewModel.isLoading ? null : _viewModel.loadQuotes,
              ),
            ],
          ),
          body: _viewModel.isLoading
              ? Center(
                  child: CircularProgressIndicator(color: greenPrimary),
                )
              : _viewModel.errorMessage != null
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
                              _viewModel.errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: greyText),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _viewModel.loadQuotes,
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
                                final ativa = _viewModel.activeCurrencyCode == sigla;

                                return GestureDetector(
                                  onTap: () {
                                    final valorLimpo = _controllerConversor.text
                                        .replaceAll('.', '')
                                        .replaceAll(',', '.');
                                    final valorEmReais = double.tryParse(valorLimpo) ?? 0.0;
                                    _viewModel.setActiveCurrency(sigla, valorEmReais);
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
                                  onChanged: _onConverterChanged,
                                  keyboardType: const TextInputType.numberWithOptions(
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
                                          '${_viewModel.conversionResult.toStringAsFixed(4).replaceAll('.', ',')} ${_viewModel.activeCurrencyCode}',
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
                              onPressed: _viewModel.loadQuotes,
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
                          if (_viewModel.lastUpdated != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Center(
                                child: Text(
                                  'Atualizado em ${_formatarHora(_viewModel.lastUpdated!)}',
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
                          ..._viewModel.quotes.map((quote) => _buildMoedaCardFromQuote(quote)),
                        ],
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildMoedaCardFromQuote(CurrencyQuote quote) {
    final valorFormatado = _formatarMoedaPtBr(quote.bid.toDouble());
    final variacaoFormatada = '${quote.pctChange.toStringAsFixed(2)}%';

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
                  quote.code == 'BTC' ? '₿' : '\$',
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
                    quote.name.isNotEmpty ? quote.name.split('/').first : quote.code,
                    style: TextStyle(
                      color: greenDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        quote.code,
                        style: TextStyle(color: greyText),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        variacaoFormatada,
                        style: TextStyle(
                          color: quote.isPositiveVariation ? greenPrimary : Colors.red,
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
            'R\$ $valorFormatado',
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