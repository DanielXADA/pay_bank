import 'package:flutter/material.dart';

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({super.key});

  @override
  State<PrincipalPage> createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> {
  double _saldoAtual = 0.0;
  final _controladorDeposito = TextEditingController();

  void _mostrarCaixaDeposito() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Depositar Dinheiro'),
          content: TextField(
            controller: _controladorDeposito,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Valor do depósito',
              prefixText: 'R\$ ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final textoValor = _controladorDeposito.text.replaceAll(',', '.');
                final valorDeposito = double.tryParse(textoValor);
                
                if (valorDeposito != null && valorDeposito > 0) {
                  setState(() {
                    _saldoAtual += valorDeposito;
                  });
                }
                
                _controladorDeposito.clear();
                Navigator.pop(context); // Fecha a janela
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dadosUsuario = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final nomeCliente = dadosUsuario?['nome'] ?? 'Visitante';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay Bank - Home'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            icon: const Icon(Icons.exit_to_app),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            color: Colors.green.shade50,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Olá, $nomeCliente!', style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 10),
                const Text('Saldo disponível:', style: TextStyle(color: Colors.grey)),
                Text(
                  'R\$ ${_saldoAtual.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet, color: Colors.orange),
            title: const Text('Depositar Dinheiro'),
            subtitle: const Text('Adicionar saldo para a conta'),
            onTap: _mostrarCaixaDeposito,
          ),
          ListTile(
            leading: const Icon(Icons.pix, color: Colors.green),
            title: const Text('Fazer Transferência PIX'),
            onTap: () => Navigator.pushNamed(context, '/transferencia', arguments: dadosUsuario),
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on, color: Colors.blue),
            title: const Text('Ver Cotações'),
            subtitle: const Text('Dólar, Euro e Bitcoin em tempo real'),
            onTap: () => Navigator.pushNamed(
              context,
              '/cotacao',
              arguments: {
                'titulo': 'Cotação PayBank',
                'moedaInicial': 'USDBRL',
              },
            ),
          ),
        ],
      ),
    );
  }
}