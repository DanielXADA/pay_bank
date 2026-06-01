import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../database/db_helper.dart';

class MeusDadosPage extends StatefulWidget {
  const MeusDadosPage({super.key});

  @override
  State<MeusDadosPage> createState() => _MeusDadosPageState();
}

class _MeusDadosPageState extends State<MeusDadosPage> {
  final Color greenPrimary = const Color(0xFF1DB954);
  final Color greenDark = const Color(0xFF191414);
  final Color greyBackground = const Color(0xFFF8F9FA);
  final Color greyText = const Color(0xFF6C757D);

  Map<String, dynamic> _usuarioDados = {};
  bool _inicializado = false;
  bool _buscandoCep = false;
  bool _editando = false;

  final _controladorEmail = TextEditingController();
  final _controladorCelular = TextEditingController();
  final _controladorCep = TextEditingController();
  final _controladorRua = TextEditingController();
  final _controladorBairro = TextEditingController();
  final _controladorCidade = TextEditingController();
  final _controladorEstado = TextEditingController();
  final _controladorNumero = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inicializado) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _usuarioDados = Map<String, dynamic>.from(args);
        _atualizarDadosLocais();
      }
      _inicializado = true;
    }
  }

  Future<void> _atualizarDadosLocais() async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    final maps = await db.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [_usuarioDados['id']],
    );
    if (maps.isNotEmpty && mounted) {
      setState(() {
        _usuarioDados = Map<String, dynamic>.from(maps.first);
        _controladorEmail.text = _usuarioDados['email'] ?? '';
        _controladorCelular.text = _usuarioDados['telefone'] ?? '';
        _controladorCep.text = _usuarioDados['cep'] ?? '';
        
        String enderecoCompleto = _usuarioDados['endereco'] ?? '';
        if (enderecoCompleto.isNotEmpty) {
          _controladorRua.text = enderecoCompleto;
        }
      });
    }
  }

  Future<void> _buscarCEP() async {
    final cepDigitado = _controladorCep.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cepDigitado.length != 8) {
      _mostrarMensagem('Digite um CEP válido com 8 números.');
      return;
    }

    setState(() {
      _buscandoCep = true;
    });

    try {
      final url = Uri.parse('https://viacep.com.br/ws/$cepDigitado/json/');
      final cliente = HttpClient();
      final requisicao = await cliente.getUrl(url);
      final resposta = await requisicao.close();

      if (resposta.statusCode == 200) {
        final corpoResposta = await resposta.transform(utf8.decoder).join();
        final dadosCep = jsonDecode(corpoResposta);

        if (dadosCep['erro'] == true) {
          _mostrarMensagem('CEP não encontrado.');
        } else {
          setState(() {
            _controladorRua.text = dadosCep['logradouro'] ?? '';
            _controladorBairro.text = dadosCep['bairro'] ?? '';
            _controladorCidade.text = dadosCep['localidade'] ?? '';
            _controladorEstado.text = dadosCep['uf'] ?? '';
          });
        }
      } else {
        _mostrarMensagem('Erro ao buscar o CEP.');
      }
    } catch (e) {
      _mostrarMensagem('Erro de conexão ao buscar o CEP.');
    } finally {
      setState(() {
        _buscandoCep = false;
      });
    }
  }

  void _solicitarSenhaParaEditar() {
    final controladorSenhaConfirmacao = TextEditingController();
    bool ocultarSenha = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                'Confirmar Identidade',
                style: TextStyle(color: greenDark, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Digite sua senha de acesso (8 dígitos) para liberar a edição.',
                    style: TextStyle(color: greyText, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controladorSenhaConfirmacao,
                    obscureText: ocultarSenha,
                    maxLength: 8,
                    decoration: InputDecoration(
                      labelText: 'Senha de Acesso',
                      labelStyle: TextStyle(color: greyText),
                      suffixIcon: IconButton(
                        icon: Icon(ocultarSenha ? Icons.visibility_off : Icons.visibility, color: greyText),
                        onPressed: () {
                          setDialogState(() {
                            ocultarSenha = !ocultarSenha;
                          });
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: greenPrimary, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () {
                    String senhaDB = (_usuarioDados['senha'] ?? '').toString();
                    if (controladorSenhaConfirmacao.text == senhaDB) {
                      Navigator.pop(context);
                      setState(() {
                        _editando = true;
                      });
                    } else {
                      _mostrarMensagem('Senha incorreta! Acesso negado.');
                    }
                  },
                  child: Text('Confirmar', style: TextStyle(color: greenPrimary, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _salvarAlteracoes() async {
    if (_controladorEmail.text.trim().isEmpty || _controladorCelular.text.trim().isEmpty) {
      _mostrarMensagem('E-mail e Celular são obrigatórios.');
      return;
    }

    String enderecoMontado = _controladorRua.text.trim();
    if (_controladorNumero.text.trim().isNotEmpty) {
      enderecoMontado += ', Nº ${_controladorNumero.text.trim()}';
    }
    if (_controladorBairro.text.trim().isNotEmpty) {
      enderecoMontado += ' - ${_controladorBairro.text.trim()}';
    }
    if (_controladorCidade.text.trim().isNotEmpty) {
      enderecoMontado += ', ${_controladorCidade.text.trim()}/${_controladorEstado.text.trim()}'; // 👈 Corrigido aqui!
    }

    final dadosAtualizados = {
      'email': _controladorEmail.text.trim(),
      'telefone': _controladorCelular.text.trim(),
      'cep': _controladorCep.text.trim(),
      'endereco': enderecoMontado,
    };

    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    await db.update(
      'usuarios', 
      dadosAtualizados, 
      where: 'id = ?', 
      whereArgs: [_usuarioDados['id']],
    );

    _mostrarMensagem('Dados atualizados com sucesso!');
    
    if (mounted) {
      Navigator.pop(context);
    }
  }
  
  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Widget _buildDataCardFixo(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: greyBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
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

  Widget _buildInputField(String label, TextEditingController controlador, TextInputType tipoTeclado) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controlador,
        keyboardType: tipoTeclado,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: greyText),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: greenPrimary, width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            _buildDataCardFixo('Nome Completo', _usuarioDados['nome'] ?? '-'),
            _buildDataCardFixo('CPF', _usuarioDados['cpf'] ?? '-'),
            _buildDataCardFixo('Data de Nascimento', _usuarioDados['data_nascimento'] ?? '-'),
            
            const SizedBox(height: 20),
            Text('Localidade e Endereço', style: TextStyle(color: greenDark, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            if (!_editando) ...[
              _buildDataCardFixo('CEP', _usuarioDados['cep'] ?? 'Não informado'),
              _buildDataCardFixo('Endereço', _usuarioDados['endereco'] ?? 'Não informado'),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controladorCep,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'CEP',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _buscandoCep ? null : _buscarCEP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: greenPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _buscandoCep 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Buscar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _buildInputField('Logradouro/Rua', _controladorRua, TextInputType.text),
              _buildInputField('Bairro', _controladorBairro, TextInputType.text),
              Row(
                children: [
                  Expanded(flex: 3, child: _buildInputField('Cidade', _controladorCidade, TextInputType.text)),
                  const SizedBox(width: 12),
                  Expanded(flex: 1, child: _buildInputField('UF', _controladorEstado, TextInputType.text)),
                ],
              ),
              _buildInputField('Número da Casa', _controladorNumero, TextInputType.number),
            ],
            
            const SizedBox(height: 20),
            Text('Canais de Contato', style: TextStyle(color: greenDark, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            if (!_editando) ...[
              _buildDataCardFixo('Número de Celular', _usuarioDados['telefone'] ?? '-'),
              _buildDataCardFixo('E-mail', _usuarioDados['email'] ?? '-'),
            ] else ...[
              _buildInputField('Número de Celular', _controladorCelular, TextInputType.phone),
              _buildInputField('E-mail', _controladorEmail, TextInputType.emailAddress),
            ],
            
            const SizedBox(height: 20),
            Text('Dados Bancários', style: TextStyle(color: greenDark, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildDataCardFixo('Agência', _usuarioDados['agencia'] ?? '0001'),
            _buildDataCardFixo('Conta Corrente', _usuarioDados['numero_conta'] ?? '00000-0'),
            _buildDataCardFixo('Instituição', 'Pay Bank S.A.'),
            
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _editando ? _salvarAlteracoes : _solicitarSenhaParaEditar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: greenPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _editando ? 'Salvar Alterações' : 'Alterar Dados',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}