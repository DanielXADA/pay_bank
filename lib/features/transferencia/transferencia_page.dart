import 'package:flutter/material.dart';
import 'dart:math';

class TransferenciaPage extends StatefulWidget {
  const TransferenciaPage({super.key});

  @override
  State<TransferenciaPage> createState() => _TransferenciaPageState();
}

class _TransferenciaPageState extends State<TransferenciaPage> {
  final _valorController = TextEditingController();
  final _chaveController = TextEditingController();

  String _gerarChaveAleatoria() {
    const caracteres = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      32, (_) => caracteres.codeUnitAt(random.nextInt(caracteres.length))
    ));
  }

  void _abrirMenuChaves() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Registrar chaves', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              ListTile(
                leading: const Icon(Icons.badge),
                title: const Text('CPF'),
                trailing: const Icon(Icons.add),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chave CPF ativada!')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.smartphone),
                title: const Text('Celular'),
                trailing: const Icon(Icons.add),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chave Celular ativada!')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('E-mail'),
                trailing: const Icon(Icons.add),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chave E-mail ativada!')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.shuffle),
                title: const Text('Chave aleatória'),
                trailing: const Icon(Icons.add),
                onTap: () {
                  final novaChave = _gerarChaveAleatoria();
                  Navigator.pop(context);
                  // O Rian vai salvar essa 'novaChave' no banco depois
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chave gerada: $novaChave')));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Área PIX')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Registrar ou trazer chaves', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Registre uma nova chave para sua conta'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _abrirMenuChaves,
            ),
            const Divider(),
            const SizedBox(height: 20),
            
            const Text('Qual é o valor?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _valorController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                prefixText: 'R\$ ',
                border: InputBorder.none,
                hintText: '0,00',
              ),
            ),
            const Divider(),
            const SizedBox(height: 20),
            const Text('Chave PIX do recebedor:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _chaveController,
              decoration: const InputDecoration(
                labelText: 'CPF, E-mail, Celular ou Chave Aleatória',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIX em desenvolvimento!')));
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar PIX', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}