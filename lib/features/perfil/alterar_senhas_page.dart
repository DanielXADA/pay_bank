import 'package:flutter/material.dart';
import '../../presentation/viewmodels/profile_viewmodel.dart';

/// View puramente declarativa no padrão MVVM.
///
/// Não executa queries SQLite. Toda a lógica de redefinição de senhas e PIN
/// com validações de segurança é gerenciada pelo [ProfileViewModel].
class AlterarSenhasPage extends StatefulWidget {
  const AlterarSenhasPage({super.key});

  @override
  State<AlterarSenhasPage> createState() => _AlterarSenhasPageState();
}

class _AlterarSenhasPageState extends State<AlterarSenhasPage> {
  final Color greenPrimary = const Color(0xFF1DB954);
  final Color greenDark = const Color(0xFF191414);
  final Color greyText = const Color(0xFF6C757D);

  late final ProfileViewModel _viewModel;
  bool _inicializado = false;

  final _controladorSenha6 = TextEditingController();
  final _controladorSenha8 = TextEditingController();
  final _controladorSenha8Atual = TextEditingController();

  bool _ocultarSenha6 = true;
  bool _ocultarSenha8 = true;
  bool _ocultarSenha8Atual = true;

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel();
    _viewModel.addListener(_onViewModelStateChanged);
  }

  void _onViewModelStateChanged() {
    if (!mounted) return;

    if (_viewModel.errorMessage != null) {
      _mostrarMensagem(_viewModel.errorMessage!, isError: true);
      _viewModel.clearError();
    } else if (_viewModel.successMessage != null) {
      _mostrarMensagem(_viewModel.successMessage!, isError: false);
      _viewModel.clearSuccess();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inicializado) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['nome_usuario'] != null) {
        _viewModel.loadUser(args['nome_usuario']);
      }
      _inicializado = true;
    }
  }

  @override
  void dispose() {
    _controladorSenha6.dispose();
    _controladorSenha8.dispose();
    _controladorSenha8Atual.dispose();
    _viewModel.removeListener(_onViewModelStateChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _mostrarMensagem(String texto, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: isError ? Colors.redAccent.shade700 : greenPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _salvarSenha6() async {
    final novaSenha = _controladorSenha6.text.trim();
    if (novaSenha.length != 6) {
      _mostrarMensagem('A senha de transação deve ter exatamente 6 números.');
      return;
    }

    final sucesso = await _viewModel.changeTransactionPin(
      currentPin: '',
      newPin: novaSenha,
    );

    if (sucesso) {
      _controladorSenha6.clear();
    }
  }

  Future<void> _salvarSenha8() async {
    final senhaAtual = _controladorSenha8Atual.text.trim();
    final novaSenha = _controladorSenha8.text.trim();

    if (senhaAtual.isEmpty) {
      _mostrarMensagem('Informe sua senha de acesso atual para confirmar.');
      return;
    }

    if (novaSenha.length < 8) {
      _mostrarMensagem('A nova senha de acesso deve ter no mínimo 8 dígitos.');
      return;
    }

    final sucesso = await _viewModel.changeAccessPassword(
      currentPassword: senhaAtual,
      newPassword: novaSenha,
    );

    if (sucesso) {
      _controladorSenha8.clear();
      _controladorSenha8Atual.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Segurança e Senhas',
              style: TextStyle(color: greenDark, fontWeight: FontWeight.bold),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: greenDark),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Senha de Transações (6 dígitos)',
                  style: TextStyle(color: greenDark, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Usada para autorizar PIX, transferências e alterações cadastrais críticas.',
                  style: TextStyle(color: greyText, fontSize: 14),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _controladorSenha6,
                  obscureText: _ocultarSenha6,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Nova senha de 6 números',
                    labelStyle: TextStyle(color: greyText),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _ocultarSenha6 ? Icons.visibility_off : Icons.visibility,
                        color: greyText,
                      ),
                      onPressed: () => setState(() => _ocultarSenha6 = !_ocultarSenha6),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _viewModel.isLoading ? null : _salvarSenha6,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: greenDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _viewModel.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Atualizar Senha de 6 Dígitos',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
                Text(
                  'Senha de Acesso (Login)',
                  style: TextStyle(color: greenDark, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Usada para entrar no aplicativo e acessar seus serviços bancários.',
                  style: TextStyle(color: greyText, fontSize: 14),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _controladorSenha8Atual,
                  obscureText: _ocultarSenha8Atual,
                  maxLength: 16,
                  decoration: InputDecoration(
                    labelText: 'Senha atual',
                    labelStyle: TextStyle(color: greyText),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _ocultarSenha8Atual ? Icons.visibility_off : Icons.visibility,
                        color: greyText,
                      ),
                      onPressed: () => setState(() => _ocultarSenha8Atual = !_ocultarSenha8Atual),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _controladorSenha8,
                  obscureText: _ocultarSenha8,
                  maxLength: 16,
                  decoration: InputDecoration(
                    labelText: 'Nova senha de acesso (mínimo 8 dígitos)',
                    labelStyle: TextStyle(color: greyText),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _ocultarSenha8 ? Icons.visibility_off : Icons.visibility,
                        color: greyText,
                      ),
                      onPressed: () => setState(() => _ocultarSenha8 = !_ocultarSenha8),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _viewModel.isLoading ? null : _salvarSenha8,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: greenPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _viewModel.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Atualizar Senha de Acesso',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}