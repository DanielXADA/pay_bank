import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'dart:math';
import '../../database/db_helper.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _userController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cpfController = TextEditingController();
  final _nascimentoController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _cepController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _ocultarSenha = true;
  bool _ocultarConfirmarSenha = true;

  var cpfMask = MaskTextInputFormatter(mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});
  var foneMask = MaskTextInputFormatter(mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});
  var cepMask = MaskTextInputFormatter(mask: '#####-###', filter: {"#": RegExp(r'[0-9]')});
  var dataMask = MaskTextInputFormatter(mask: '##/##/####', filter: {"#": RegExp(r'[0-9]')});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pay Bank - Abertura de Conta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text('Dados Pessoais', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              
              TextFormField(
                controller: _nomeController, 
                decoration: const InputDecoration(labelText: 'Nome Completo *'),
                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              
              TextFormField(
                controller: _cpfController, 
                inputFormatters: [cpfMask], 
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'CPF *', hintText: '000.000.000-00'),
                validator: (value) => value!.length < 14 ? 'CPF inválido' : null,
              ),

              TextFormField(
                controller: _nascimentoController, 
                inputFormatters: [dataMask],
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Data de Nascimento *', hintText: 'DD/MM/AAAA'),
                validator: (value) => value!.length < 10 ? 'Data inválida' : null,
              ),

              const SizedBox(height: 20),
              const Text('Contato e Endereço', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              TextFormField(
                controller: _emailController, 
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail *'),
                validator: (value) => value!.contains('@') ? null : 'E-mail inválido',
              ),

              TextFormField(
                controller: _telefoneController, 
                inputFormatters: [foneMask],
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefone Celular *'),
                validator: (value) => value!.length < 15 ? 'Telefone inválido' : null,
              ),

              TextFormField(
                controller: _cepController, 
                inputFormatters: [cepMask],
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'CEP *'),
                validator: (value) => value!.length < 9 ? 'CEP inválido' : null,
              ),

              TextFormField(
                controller: _enderecoController, 
                decoration: const InputDecoration(labelText: 'Endereço Completo *'),
                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
              ),

              const SizedBox(height: 20),
              const Text('Acesso ao App', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              TextFormField(
                controller: _userController, 
                decoration: const InputDecoration(labelText: 'Nome de Usuário (@) *'),
                validator: (value) => value!.isEmpty ? 'Crie um nome de usuário' : null,
              ),

              TextFormField(
                controller: _senhaController, 
                obscureText: _ocultarSenha,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Senha (mínimo 6 dígitos numéricos) *',
                  suffixIcon: IconButton(
                    icon: Icon(_ocultarSenha ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _ocultarSenha = !_ocultarSenha;
                      });
                    },
                  ),
                ), 
                validator: (value) => value!.length < 6 ? 'A senha deve ter pelo menos 6 números' : null,
              ),

              TextFormField(
                controller: _confirmarSenhaController, 
                obscureText: _ocultarConfirmarSenha,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Confirmar Senha *',
                  suffixIcon: IconButton(
                    icon: Icon(_ocultarConfirmarSenha ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _ocultarConfirmarSenha = !_ocultarConfirmarSenha;
                      });
                    },
                  ),
                ), 
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, confirme sua senha';
                  }
                  if (value != _senhaController.text) {
                    return 'As senhas não são iguais';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        final geradorAleatorio = Random();
                        final numeroContaGerado = '${geradorAleatorio.nextInt(90000) + 10000}-${geradorAleatorio.nextInt(9)}';

                        final db = DatabaseHelper.instance;
                        await db.gravarUsuario({
                          'nome': _nomeController.text,
                          'nome_usuario': _userController.text,
                          'senha': _senhaController.text,
                          'email': _emailController.text,
                          'telefone': _telefoneController.text,
                          'cpf': _cpfController.text,
                          'data_nascimento': _nascimentoController.text,
                          'endereco': _enderecoController.text,
                          'cep': _cepController.text,
                          'agencia': '0001',
                          'numero_conta': numeroContaGerado,
                          'saldo': 0.0,
                        });
                        
                        if (!mounted) return;
                        
                        Navigator.pop(context); 
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conta criada com sucesso!')));
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar. Verifique se o CPF ou Usuário já existem. $e')));
                      }
                    }
                  },
                  child: const Text('Finalizar Cadastro', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}