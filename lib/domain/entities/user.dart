import 'account.dart';
import 'address.dart';

/// Entidade de Usuário / Correntista do PayBank.
class User {
  final int? id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String cpf;
  final String birthDate;
  final Address address;
  final String? randomPixKey;
  final String? facePhotoPath;
  final String? documentPhotoPath;
  final String agency;
  final String accountNumber;
  final bool isCpfKeyActive;
  final bool isEmailKeyActive;
  final bool isPhoneKeyActive;
  final Account? account;

  const User({
    this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.cpf,
    required this.birthDate,
    required this.address,
    this.randomPixKey,
    this.facePhotoPath,
    this.documentPhotoPath,
    required this.agency,
    required this.accountNumber,
    this.isCpfKeyActive = true,
    this.isEmailKeyActive = false,
    this.isPhoneKeyActive = false,
    this.account,
  });

  User copyWith({
    int? id,
    String? name,
    String? username,
    String? email,
    String? phone,
    String? cpf,
    String? birthDate,
    Address? address,
    String? randomPixKey,
    String? facePhotoPath,
    String? documentPhotoPath,
    String? agency,
    String? accountNumber,
    bool? isCpfKeyActive,
    bool? isEmailKeyActive,
    bool? isPhoneKeyActive,
    Account? account,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      cpf: cpf ?? this.cpf,
      birthDate: birthDate ?? this.birthDate,
      address: address ?? this.address,
      randomPixKey: randomPixKey ?? this.randomPixKey,
      facePhotoPath: facePhotoPath ?? this.facePhotoPath,
      documentPhotoPath: documentPhotoPath ?? this.documentPhotoPath,
      agency: agency ?? this.agency,
      accountNumber: accountNumber ?? this.accountNumber,
      isCpfKeyActive: isCpfKeyActive ?? this.isCpfKeyActive,
      isEmailKeyActive: isEmailKeyActive ?? this.isEmailKeyActive,
      isPhoneKeyActive: isPhoneKeyActive ?? this.isPhoneKeyActive,
      account: account ?? this.account,
    );
  }
}
