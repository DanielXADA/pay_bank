import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/user_model.dart';
import '../../presentation/viewmodels/profile_viewmodel.dart';

/// View puramente declarativa no padrão MVVM.
///
/// Exibe ciclo de vida da conta, status KYC e orquestra ações de perfil pelo [ProfileViewModel].
class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final Color greenPrimary = const Color(0xFF1DB954);
  final Color greenDark = const Color(0xFF191414);
  final Color greyBackground = const Color(0xFFF8F9FA);
  final Color greyText = const Color(0xFF6C757D);

  late final ProfileViewModel _viewModel;
  bool _inicializado = false;

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel();
    _viewModel.addListener(_onViewModelStateChanged);
  }

  void _onViewModelStateChanged() {
    if (!mounted) return;

    if (_viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage!),
          backgroundColor: Colors.redAccent.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _viewModel.clearError();
    } else if (_viewModel.successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.successMessage!),
          backgroundColor: greenPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    _viewModel.removeListener(_onViewModelStateChanged);
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _capturarImagem(ImageSource origem) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: origem);

    if (image != null) {
      await _viewModel.updateFacePhoto(image.path);
    }
  }

  void _selecionarFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final temFoto = _viewModel.currentUser?.facePhotoPath != null &&
            _viewModel.currentUser!.facePhotoPath!.isNotEmpty;

        return SafeArea(
          child: Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Foto de Perfil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: greenPrimary),
                title: const Text('Tirar Foto (Câmera)'),
                onTap: () {
                  Navigator.pop(context);
                  _capturarImagem(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: greenPrimary),
                title: const Text('Escolher da Galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _capturarImagem(ImageSource.gallery);
                },
              ),
              if (temFoto)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Remover Foto Atual',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _viewModel.removeFacePhoto();
                  },
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading && _viewModel.currentUser == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: greenPrimary)),
          );
        }

        final user = _viewModel.currentUser;
        final nome = user?.name ?? 'Correntista';
        final email = user?.email ?? '';
        final caminhoFoto = user?.facePhotoPath;

        final userMap = user != null ? UserModel.fromDomain(user).toMap() : <String, dynamic>{};
        if (user != null) {
          userMap['id'] = user.id;
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Meu Perfil',
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
              children: [
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _selecionarFoto,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            _buildAvatar(caminhoFoto),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: greenPrimary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        nome,
                        style: TextStyle(color: greenDark, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(email, style: TextStyle(color: greyText, fontSize: 14)),
                      const SizedBox(height: 15),

                      // Status de Core Banking (KYC e Ciclo de Vida da Conta)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: greenPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: greenPrimary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user, color: greenPrimary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _viewModel.accountLifecycleStatus,
                              style: TextStyle(color: greenDark, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const Text(' • ', style: TextStyle(color: Colors.grey)),
                            Text(
                              _viewModel.kycStatusDescription,
                              style: TextStyle(color: greenPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 35),
                _buildMenuItem(context, Icons.person_outline, 'Meus Dados', '/meus_dados', userMap),
                _buildMenuItem(context, Icons.vpn_key_outlined, 'Minhas Chaves PIX', '/minhas_chaves', userMap),
                _buildMenuItem(context, Icons.security_outlined, 'Segurança e Senhas', '/alterar_senhas', userMap),
                const SizedBox(height: 20),
                _buildLogoutButton(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(dynamic caminhoFoto) {
    if (caminhoFoto != null && caminhoFoto.toString().isNotEmpty) {
      final arquivo = File(caminhoFoto);
      if (arquivo.existsSync()) {
        return CircleAvatar(radius: 50, backgroundImage: FileImage(arquivo));
      }
    }
    return CircleAvatar(
      radius: 50,
      backgroundColor: greyBackground,
      child: Icon(Icons.person, color: greenPrimary, size: 50),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    String? route,
    Map<String, dynamic> args,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: greyBackground, width: 2),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: greenPrimary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: greenPrimary),
        ),
        title: Text(title, style: TextStyle(color: greenDark, fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.arrow_forward_ios, color: greyText, size: 16),
        onTap: () async {
          if (route != null && _viewModel.currentUser != null) {
            await Navigator.pushNamed(context, route, arguments: args);
            await _viewModel.loadUser(_viewModel.currentUser!.username);
          }
        },
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        child: const Text(
          'Sair da Conta',
          style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}