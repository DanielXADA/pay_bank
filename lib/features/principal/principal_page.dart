import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../database/db_helper.dart';

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({super.key});

  @override
  State<PrincipalPage> createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> {
  Map<String, dynamic>? _usuarioDados;
  List<Map<String, dynamic>> _listaTransferencias = [];
  final _controladorDeposito = TextEditingController();
  bool _carregando = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_usuarioDados == null) {
      final dadosIniciais =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (dadosIniciais != null) {
        _carregarDadosReal(dadosIniciais['nome_usuario']);
      }
    }
  }

  Future<void> _carregarDadosReal(String nomeUsuario) async {
    final bancoDados = DatabaseHelper.instance;
    final usuarioAtualizado =
        await bancoDados.buscarUsuarioPorLogin(nomeUsuario);

    if (usuarioAtualizado != null) {
      final transferencias =
          await bancoDados.buscarTransferenciasDoUsuario(usuarioAtualizado['id']);

      if (mounted) {
        setState(() {
          _usuarioDados = usuarioAtualizado;
          _listaTransferencias = transferencias;
          _carregando = false;
        });
      }
    }
  }

  Widget _fotoPerfilHome() {
    final caminhoFoto = _usuarioDados?['foto_rosto'];

    if (caminhoFoto != null && caminhoFoto.toString().isNotEmpty) {
      final arquivo = File(caminhoFoto);

      if (arquivo.existsSync()) {
        return CircleAvatar(
          radius: 16,
          backgroundImage: FileImage(arquivo),
        );
      }
    }

    return const Icon(Icons.account_circle, size: 28);
  }

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
              onPressed: () async {
                final textoValor =
                    _controladorDeposito.text.replaceAll(',', '.');
                final valorDeposito = double.tryParse(textoValor);

                if (valorDeposito != null &&
                    valorDeposito > 0 &&
                    _usuarioDados != null) {
                  final bancoDados = DatabaseHelper.instance;
                  final banco = await bancoDados.database;

                  final saldoAntigo =
                      (_usuarioDados!['saldo'] as num?)?.toDouble() ?? 0.0;

                  final novoSaldo = saldoAntigo + valorDeposito;

                  await banco.update(
                    'usuarios',
                    {'saldo': novoSaldo},
                    where: 'id = ?',
                    whereArgs: [_usuarioDados!['id']],
                  );

                  _carregarDadosReal(_usuarioDados!['nome_usuario']);
                }

                _controladorDeposito.clear();

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void _compartilharComprovanteHistorico(
    Map<String, dynamic> transferencia,
  ) {
    final valorFormatado = (transferencia['valor'] as num)
        .toDouble()
        .toStringAsFixed(2)
        .replaceAll('.', ',');

    final ehEntrada = transferencia['tipo'] == 'ENTRADA';

    final textoComprovante = '''
Comprovante PIX - Pay Bank

Tipo: ${ehEntrada ? 'Recebimento' : 'Envio'}
Valor: R\$ $valorFormatado
${ehEntrada ? 'Pagador' : 'Recebedor'}: ${transferencia['recebedor']}
Instituição: Pay Bank
Data: ${transferencia['data']}
''';

    Share.share(textoComprovante);
  }

  void _mostrarComprovanteAntigo(Map<String, dynamic> transferencia) {
    final valorFormatado = (transferencia['valor'] as num)
        .toDouble()
        .toStringAsFixed(2)
        .replaceAll('.', ',');

    final ehEntrada = transferencia['tipo'] == 'ENTRADA';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Comprovante de PIX'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(Icons.check_circle, size: 50, color: Colors.green),
              ),
              const SizedBox(height: 15),
              Text(
                'Valor: R\$ $valorFormatado',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              Text(
                ehEntrada
                    ? 'Pagador: ${transferencia['recebedor']}'
                    : 'Recebedor: ${transferencia['recebedor']}',
              ),
              const SizedBox(height: 5),
              Text('Data: ${transferencia['data']}'),
              const SizedBox(height: 5),
              const Text('Instituição: Pay Bank'),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () => _compartilharComprovanteHistorico(transferencia),
              icon: const Icon(Icons.share),
              label: const Text('Compartilhar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controladorDeposito.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando || _usuarioDados == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final nomeCliente = _usuarioDados!['nome'];
    final agencia = _usuarioDados!['agencia'] ?? '0001';
    final numeroConta = _usuarioDados!['numero_conta'] ?? '00000-0';

    final saldoObtido = (_usuarioDados!['saldo'] as num?)?.toDouble() ?? 0.0;
    final saldoFormatado = saldoObtido.toStringAsFixed(2).replaceAll('.', ',');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay Bank - Home'),
        leading: IconButton(
          icon: _fotoPerfilHome(),
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/perfil',
              arguments: _usuarioDados,
            ).then((_) {
              _carregarDadosReal(_usuarioDados!['nome_usuario']);
            });
          },
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            icon: const Icon(Icons.exit_to_app),
          ),
        ],
      ),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            color: Colors.green.shade50,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, $nomeCliente!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Agência: $agencia | Conta: $numeroConta',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Saldo disponível:',
                  style: TextStyle(color: Colors.grey),
                ),
                Text(
                  'R\$ $saldoFormatado',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          ListTile(
            leading: const Icon(
              Icons.account_balance_wallet,
              color: Colors.orange,
            ),
            title: const Text('Depositar Dinheiro'),
            subtitle: const Text('Adicionar saldo para a conta'),
            onTap: _mostrarCaixaDeposito,
          ),

          ListTile(
            leading: const Icon(Icons.pix, color: Colors.green),
            title: const Text('Fazer Transferência PIX'),
            onTap: () => Navigator.pushNamed(
              context,
              '/transferencia',
              arguments: _usuarioDados,
            ).then((_) {
              _carregarDadosReal(_usuarioDados!['nome_usuario']);
            }),
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

          const Divider(),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Histórico de transações',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          if (_listaTransferencias.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Nenhuma transferência realizada ainda.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._listaTransferencias.map((transferencia) {
              final valorFormatadoItem = (transferencia['valor'] as num)
                  .toDouble()
                  .toStringAsFixed(2)
                  .replaceAll('.', ',');

              final ehEntrada = transferencia['tipo'] == 'ENTRADA';

              return ListTile(
                leading: Icon(
                  ehEntrada ? Icons.arrow_downward : Icons.arrow_upward,
                  color: ehEntrada ? Colors.green : Colors.red,
                ),
                title: Text(
                  ehEntrada
                      ? 'PIX recebido de ${transferencia['recebedor']}'
                      : 'PIX enviado para ${transferencia['recebedor']}',
                ),
                subtitle: Text(transferencia['data']),
                trailing: Text(
                  '${ehEntrada ? "+" : "-"} R\$ $valorFormatadoItem',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ehEntrada ? Colors.green : Colors.red,
                  ),
                ),
                onTap: () => _mostrarComprovanteAntigo(transferencia),
              );
            }),
        ],
      ),
    );
  }
}