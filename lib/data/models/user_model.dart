import '../../domain/entities/account.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/user.dart';

class UserModel {
  final int? id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String cpf;
  final String birthDate;
  final String address;
  final String cep;
  final String? randomPixKey;
  final String? facePhotoPath;
  final String? documentPhotoPath;
  final String agency;
  final String accountNumber;
  final bool isCpfKeyActive;
  final bool isEmailKeyActive;
  final bool isPhoneKeyActive;

  const UserModel({
    this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.cpf,
    required this.birthDate,
    required this.address,
    required this.cep,
    this.randomPixKey,
    this.facePhotoPath,
    this.documentPhotoPath,
    required this.agency,
    required this.accountNumber,
    this.isCpfKeyActive = true,
    this.isEmailKeyActive = false,
    this.isPhoneKeyActive = false,
  });

  factory UserModel.fromDomain(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      username: user.username,
      email: user.email,
      phone: user.phone,
      cpf: user.cpf,
      birthDate: user.birthDate,
      address: user.address.formattedOneLine,
      cep: user.address.cep,
      randomPixKey: user.randomPixKey,
      facePhotoPath: user.facePhotoPath,
      documentPhotoPath: user.documentPhotoPath,
      agency: user.agency,
      accountNumber: user.accountNumber,
      isCpfKeyActive: user.isCpfKeyActive,
      isEmailKeyActive: user.isEmailKeyActive,
      isPhoneKeyActive: user.isPhoneKeyActive,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['nome'] as String,
      username: map['nome_usuario'] as String,
      email: map['email'] as String,
      phone: map['telefone'] as String,
      cpf: map['cpf'] as String,
      birthDate: map['data_nascimento'] as String,
      address: map['endereco'] as String,
      cep: map['cep'] as String,
      randomPixKey: map['chave_aleatoria'] as String?,
      facePhotoPath: map['foto_rosto'] as String?,
      documentPhotoPath: map['foto_documento'] as String?,
      agency: (map['agencia'] as String?) ?? '0001',
      accountNumber: (map['numero_conta'] as String?) ?? '',
      isCpfKeyActive: (map['chave_cpf_ativa'] as int?) == 1,
      isEmailKeyActive: (map['chave_email_ativa'] as int?) == 1,
      isPhoneKeyActive: (map['chave_telefone_ativa'] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap({String? password, String? transactionPassword}) {
    final map = <String, dynamic>{
      'nome': name,
      'nome_usuario': username,
      'email': email,
      'telefone': phone,
      'cpf': cpf,
      'data_nascimento': birthDate,
      'endereco': address,
      'cep': cep,
      'chave_aleatoria': randomPixKey,
      'foto_rosto': facePhotoPath,
      'foto_documento': documentPhotoPath,
      'agencia': agency,
      'numero_conta': accountNumber,
      'chave_cpf_ativa': isCpfKeyActive ? 1 : 0,
      'chave_email_ativa': isEmailKeyActive ? 1 : 0,
      'chave_telefone_ativa': isPhoneKeyActive ? 1 : 0,
    };

    if (id != null) {
      map['id'] = id;
    }
    if (password != null) {
      map['senha'] = password;
    }
    if (transactionPassword != null) {
      map['senha_transacao'] = transactionPassword;
    }

    return map;
  }

  User toDomain([Account? account]) {
    return User(
      id: id,
      name: name,
      username: username,
      email: email,
      phone: phone,
      cpf: cpf,
      birthDate: birthDate,
      address: Address(
        cep: cep,
        street: address,
        neighborhood: '',
        city: '',
        state: '',
      ),
      randomPixKey: randomPixKey,
      facePhotoPath: facePhotoPath,
      documentPhotoPath: documentPhotoPath,
      agency: agency,
      accountNumber: accountNumber,
      isCpfKeyActive: isCpfKeyActive,
      isEmailKeyActive: isEmailKeyActive,
      isPhoneKeyActive: isPhoneKeyActive,
      account: account,
    );
  }
}
