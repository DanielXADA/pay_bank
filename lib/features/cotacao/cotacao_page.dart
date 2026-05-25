import 'package:flutter/material.dart';
import '../../services/cotacao_service.dart';

class CotacaoPage extends StatefulWidget {
  const CotacaoPage({super.key});

  @override
  State<CotacaoPage> createState() => _CotacaoPageState();
}

class _CotacaoPageState extends State<CotacaoPage> {
  final CotacaoService cotacaoService = CotacaoService();
  final TextEditingController valorController = TextEditingController();

  bool carregando = true;
  bool argumentosCarregados = false;

  String? erro;
  Map<String, dynamic>? cotacoes;
  String moedaSelecionada = 'USDBRL';
  double? resultado;
  DateTime? ultimaAtualizacao;

  final Map<String, String> nomesMoedas = {
    'USDBRL': 'Dólar',
    'EURBRL': 'Euro',
    'BTCBRL': 'Bitcoin',
  };

  @override
  void initState() {
    super.initState();
    carregarCotacoes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!argumentosCarregados) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      final moedaInicial = args?['moedaInicial'];

      if (moedaInicial != null && nomesMoedas.containsKey(moedaInicial)) {
        moedaSelecionada = moedaInicial;
      }

      argumentosCarregados = true;
    }
  }

  Future<void> carregarCotacoes() async {
    setState(() {
      carregando = true;
      erro = null;
    });

    try {
      final dados = await cotacaoService.buscarCotacoes();

      setState(() {
        cotacoes = dados;
        ultimaAtualizacao = DateTime.now();
        carregando = false;
      });
    } catch (e) {
      setState(() {
        erro = 'Erro ao buscar cotações';
        carregando = false;
      });
    }
  }

  void converterValor() {
    final texto = valorController.text.replaceAll(',', '.');
    final valorReais = double.tryParse(texto);

    if (valorReais == null || cotacoes == null) {
      setState(() {
        resultado = null;
      });
      return;
    }

    final cotacao = double.parse(cotacoes![moedaSelecionada]['bid']);

    setState(() {
      resultado = valorReais / cotacao;
    });
  }

  String formatarHora(DateTime data) {
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }

  @override
  void dispose() {
    valorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final titulo = args?['titulo'] ?? 'Cotação PayBank';

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: carregando
            ? const Center(child: CircularProgressIndicator())
            : erro != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(erro!),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: carregarCotacoes,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    children: [
                      const Text(
                        'Câmbio Inteligente',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Consulte moedas em tempo real e simule conversões.',
                      ),

                      const SizedBox(height: 12),

                      if (ultimaAtualizacao != null)
                        Text(
                          'Atualizado às ${formatarHora(ultimaAtualizacao!)}',
                        ),

                      const SizedBox(height: 20),

                      ...nomesMoedas.keys.map((codigo) {
                        final moeda = cotacoes![codigo];

                        return Card(
                          child: ListTile(
                            title: Text(nomesMoedas[codigo]!),
                            subtitle: Text(
                              '1 ${moeda['code']} = R\$ ${moeda['bid']}',
                            ),
                            trailing: Text('${moeda['pctChange']}%'),
                          ),
                        );
                      }),

                      const SizedBox(height: 20),

                      DropdownButtonFormField<String>(
                        value: moedaSelecionada,
                        decoration: const InputDecoration(
                          labelText: 'Escolha a moeda',
                          border: OutlineInputBorder(),
                        ),
                        items: nomesMoedas.entries.map((item) {
                          return DropdownMenuItem(
                            value: item.key,
                            child: Text(item.value),
                          );
                        }).toList(),
                        onChanged: (valor) {
                          setState(() {
                            moedaSelecionada = valor!;
                            resultado = null;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: valorController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Valor em reais',
                          prefixText: 'R\$ ',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      ElevatedButton(
                        onPressed: converterValor,
                        child: const Text('Converter'),
                      ),

                      const SizedBox(height: 16),

                      if (resultado != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Resultado: ${resultado!.toStringAsFixed(4)} ${cotacoes![moedaSelecionada]['code']}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      OutlinedButton(
                        onPressed: carregarCotacoes,
                        child: const Text('Atualizar cotação'),
                      ),
                    ],
                  ),
      ),
    );
  }
}