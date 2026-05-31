import 'package:flutter/material.dart';

class MeusDadosPage extends StatelessWidget {
  const MeusDadosPage({super.key});

  final Color greenPrimary = const Color(0xFF1DB954);
  final Color greenDark = const Color(0xFF191414);
  final Color greyBackground = const Color(0xFFF8F9FA);
  final Color greyText = const Color(0xFF6C757D);

  @override
  Widget build(BuildContext context) {
    final usuarioDados = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Meus Dados', style: TextStyle(color: greenDark, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: greenDark), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informações Pessoais', style: TextStyle(color: greenDark, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildDataCard('Nome Completo', usuarioDados['nome'] ?? '-'),
            _buildDataCard('CPF', usuarioDados['cpf'] ?? '-'),
            _buildDataCard('E-mail', usuarioDados['email'] ?? '-'),
            _buildDataCard('Telefone', usuarioDados['telefone'] ?? '-'),
            const SizedBox(height: 30),
            Text('Dados Bancários', style: TextStyle(color: greenDark, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildDataCard('Agência', usuarioDados['agencia'] ?? '0001'),
            _buildDataCard('Conta Corrente', usuarioDados['numero_conta'] ?? '00000-0'),
            _buildDataCard('Instituição', 'Pay Bank S.A.'),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: greyBackground, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: greyText, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(color: greenDark, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}