import 'package:flutter/material.dart';

class PrincipalPage extends StatelessWidget {
  const PrincipalPage({super.key});

  @override
  Widget build(BuildContext context) {
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Olá, Daniel!', style: TextStyle(fontSize: 20)),
                SizedBox(height: 10),
                Text('Saldo disponível:', style: TextStyle(color: Colors.grey)),
                Text(
                  'R\$ 1.250,00',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          ListTile(
            leading: const Icon(Icons.pix, color: Colors.green),
            title: const Text('Fazer Transferência PIX'),
            onTap: () => Navigator.pushNamed(context, '/transferencia'),
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