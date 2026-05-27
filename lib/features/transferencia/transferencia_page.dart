import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../database/db_helper.dart';

class TransferenciaPage extends StatefulWidget {
  const TransferenciaPage({super.key});

  @override
  State<TransferenciaPage> createState() => _TransferenciaPageState();
}

class _TransferenciaPageState extends State<TransferenciaPage> {
  int _passoAtual = 1;
  final _controladorValor = TextEditingController();
  final _controladorChave = TextEditingController();
  final _controladorSenha = TextEditingController();

  Map<String, dynamic>? _usuarioRemetente;
  Map<String, dynamic>? _usuarioRecebedor;
  double _valorTransferencia = 0.0;
  String _idTransacao = '';
  String _dataHoraTransacao = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _usuarioRemetente ??= ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  }

  String _mascararCpf(String cpf) {
    if (cpf.length < 14) return cpf;
    return '***.${cpf.substring(4, 7)}.***-**';
  }

  void _buscarChaveEAvancar() async {
    final textoValor = _controladorValor.text.replaceAll(',', '.');
    final valorDigitado = double.tryParse(textoValor);
    final chaveDigitada = _controladorChave.text.trim();

    if (_usuarioRemetente == null) return;

    final saldoDisponivel =
        (_usuarioRemetente!['saldo'] as num?)?.toDouble() ?? 0.0;

    if (valorDigitado == null || valorDigitado <= 0) {
      _mostrarMensagem('Digite um valor válido para a transferência.');
      return;
    }

    if (valorDigitado > saldoDisponivel) {
      _mostrarMensagem('Saldo insuficiente para realizar esta transferência.');
      return;
    }

    if (chaveDigitada.isEmpty) {
      _mostrarMensagem('Por favor, digite uma chave PIX.');
      return;
    }

    String chaveFormatadaCpf = chaveDigitada;
    String chaveFormatadaFone = chaveDigitada;

    if (chaveDigitada.length == 11 && int.tryParse(chaveDigitada) != null) {
      chaveFormatadaCpf =
          '${chaveDigitada.substring(0, 3)}.${chaveDigitada.substring(3, 6)}.${chaveDigitada.substring(6, 9)}-${chaveDigitada.substring(9, 11)}';

      chaveFormatadaFone =
          '(${chaveDigitada.substring(0, 2)}) ${chaveDigitada.substring(2, 7)}-${chaveDigitada.substring(7, 11)}';
    }

    final bancoDados = DatabaseHelper.instance;
    final banco = await bancoDados.database;
    List<Map<String, dynamic>> resultado = [];

    final buscaCpf = await banco.query(
      'usuarios',
      where: 'cpf = ? AND chave_cpf_ativa = 1',
      whereArgs: [chaveFormatadaCpf],
    );

    if (buscaCpf.isNotEmpty) resultado = buscaCpf;

    if (resultado.isEmpty) {
      final buscaEmail = await banco.query(
        'usuarios',
        where: 'email = ? AND chave_email_ativa = 1',
        whereArgs: [chaveDigitada],
      );

      if (buscaEmail.isNotEmpty) resultado = buscaEmail;
    }

    if (resultado.isEmpty) {
      final buscaTelefone = await banco.query(
        'usuarios',
        where: 'telefone = ? AND chave_telefone_ativa = 1',
        whereArgs: [chaveFormatadaFone],
      );

      if (buscaTelefone.isNotEmpty) resultado = buscaTelefone;
    }

    if (resultado.isEmpty) {
      final buscaAleatoria = await banco.query(
        'usuarios',
        where: 'chave_aleatoria = ?',
        whereArgs: [chaveDigitada],
      );

      if (buscaAleatoria.isNotEmpty) resultado = buscaAleatoria;
    }

    if (resultado.isEmpty) {
      _mostrarMensagem('Chave PIX não encontrada ou não está ativa no sistema.');
      return;
    }

    final recebedorEncontrado = resultado.first;

    if (recebedorEncontrado['id'] == _usuarioRemetente!['id']) {
      _mostrarMensagem('Você não pode fazer um PIX para você mesmo.');
      return;
    }

    setState(() {
      _valorTransferencia = valorDigitado;
      _usuarioRecebedor = recebedorEncontrado;
      _passoAtual = 2;
    });
  }

  void _solicitarSenhaEFinalizar() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Segurança'),
          content: TextField(
            controller: _controladorSenha,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Digite sua senha de acesso',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _controladorSenha.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_controladorSenha.text == _usuarioRemetente!['senha']) {
                  Navigator.pop(context);
                  _processarTransferenciaNoBanco();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Senha de acesso incorreta!')),
                  );
                }

                _controladorSenha.clear();
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void _processarTransferenciaNoBanco() async {
    try {
      final bancoDados = DatabaseHelper.instance;
      final banco = await bancoDados.database;

      final saldoAntigoRemetente =
          (_usuarioRemetente!['saldo'] as num?)?.toDouble() ?? 0.0;

      final saldoAntigoRecebedor =
          (_usuarioRecebedor!['saldo'] as num?)?.toDouble() ?? 0.0;

      final novoSaldoRemetente = saldoAntigoRemetente - _valorTransferencia;
      final novoSaldoRecebedor = saldoAntigoRecebedor + _valorTransferencia;

      await banco.update(
        'usuarios',
        {'saldo': novoSaldoRemetente},
        where: 'id = ?',
        whereArgs: [_usuarioRemetente!['id']],
      );

      await banco.update(
        'usuarios',
        {'saldo': novoSaldoRecebedor},
        where: 'id = ?',
        whereArgs: [_usuarioRecebedor!['id']],
      );

      final dataAtual = DateTime.now();

      _dataHoraTransacao =
          '${dataAtual.day.toString().padLeft(2, '0')}/${dataAtual.month.toString().padLeft(2, '0')}/${dataAtual.year} às ${dataAtual.hour.toString().padLeft(2, '0')}:${dataAtual.minute.toString().padLeft(2, '0')}';

      _idTransacao = 'E${dataAtual.millisecondsSinceEpoch}';

      await bancoDados.gravarTransferencia({
        'id_usuario': _usuarioRemetente!['id'],
        'recebedor': _usuarioRecebedor!['nome'],
        'valor': _valorTransferencia,
        'data': _dataHoraTransacao,
        'tipo': 'SAIDA',
      });

      await bancoDados.gravarTransferencia({
        'id_usuario': _usuarioRecebedor!['id'],
        'recebedor': _usuarioRemetente!['nome'],
        'valor': _valorTransferencia,
        'data': _dataHoraTransacao,
        'tipo': 'ENTRADA',
      });

      setState(() {
        _passoAtual = 3;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao processar transferência: $e')),
      );
    }
  }

  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  void _compartilharComprovante() {
    if (_usuarioRemetente == null || _usuarioRecebedor == null) return;

    final valorFormatado =
        _valorTransferencia.toStringAsFixed(2).replaceAll('.', ',');

    final textoComprovante = '''
Comprovante PIX - Pay Bank

Transferência realizada com sucesso.

Valor: R\$ $valorFormatado
Pagador: ${_usuarioRemetente!['nome']}
Recebedor: ${_usuarioRecebedor!['nome']}
Instituição: Pay Bank
Data e Hora: $_dataHoraTransacao
ID da Transação: $_idTransacao
''';

    Share.share(textoComprovante);
  }

  @override
  void dispose() {
    _controladorValor.dispose();
    _controladorChave.dispose();
    _controladorSenha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_usuarioRemetente == null) {
      return const Scaffold(
        body: Center(child: Text('Erro ao carregar dados da conta.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_passoAtual == 3 ? 'Comprovante' : 'Área PIX'),
        automaticallyImplyLeading: _passoAtual != 3,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _construirPassoDaTela(),
      ),
    );
  }

  Widget _construirPassoDaTela() {
    if (_passoAtual == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Qual é o valor da transferência?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controladorValor,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              prefixText: 'R\$ ',
              border: InputBorder.none,
              hintText: '0,00',
            ),
          ),
          const Divider(),
          const SizedBox(height: 25),
          const Text(
            'Chave PIX do recebedor:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controladorChave,
            decoration: const InputDecoration(
              labelText: 'CPF, E-mail, Celular ou Chave Aleatória',
              border: OutlineInputBorder(),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _buscarChaveEAvancar,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Avançar', style: TextStyle(fontSize: 18)),
          ),
        ],
      );
    }

    if (_passoAtual == 2) {
      final valorFormatado =
          _valorTransferencia.toStringAsFixed(2).replaceAll('.', ',');

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revise as informações',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 25),
          const Text(
            'Valor a ser transferido',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          Text(
            'R\$ $valorFormatado',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          const Text(
            'De (Pagador)',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          Text(
            _usuarioRemetente!['nome'],
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 15),
          const Text(
            'Para (Recebedor)',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          Text(
            _usuarioRecebedor!['nome'],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          const Text(
            'Instituição',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const Text(
            'Pay Bank - Instituição de Pagamento',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 15),
          Text(
            'Agência: ${_usuarioRecebedor!['agencia']} | Conta: ${_usuarioRecebedor!['numero_conta']}',
            style: const TextStyle(fontSize: 16),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _solicitarSenhaEFinalizar,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Confirmar Transferência',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      );
    }

    final valorFormatado =
        _valorTransferencia.toStringAsFixed(2).replaceAll('.', ',');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Icon(Icons.check_circle, size: 70, color: Colors.green),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Transferência realizada!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 30),
          const Text('Valor', style: TextStyle(color: Colors.grey)),
          Text(
            'R\$ $valorFormatado',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const Text('Pagador', style: TextStyle(color: Colors.grey)),
          Text(
            _usuarioRemetente!['nome'],
            style: const TextStyle(fontSize: 16),
          ),
          const Divider(),
          const Text('Recebedor', style: TextStyle(color: Colors.grey)),
          Text(
            _usuarioRecebedor!['nome'],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            'CPF: ${_mascararCpf(_usuarioRecebedor!['cpf'])}',
            style: const TextStyle(color: Colors.black54),
          ),
          const Divider(),
          const Text('Instituição', style: TextStyle(color: Colors.grey)),
          const Text('Pay Bank'),
          Text(
            'Agência: ${_usuarioRecebedor!['agencia']} | Conta: ${_usuarioRecebedor!['numero_conta']}',
          ),
          const Divider(),
          const Text('Data e Hora', style: TextStyle(color: Colors.grey)),
          Text(_dataHoraTransacao),
          const Divider(),
          const Text('ID da Transação', style: TextStyle(color: Colors.grey)),
          Text(_idTransacao),
          const SizedBox(height: 25),
          OutlinedButton.icon(
            onPressed: _compartilharComprovante,
            icon: const Icon(Icons.share),
            label: const Text('Compartilhar comprovante'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Voltar para o início',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}