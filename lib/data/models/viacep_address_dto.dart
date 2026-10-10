import '../../domain/entities/address.dart';

/// DTO da Camada Anti-Corrupção (ACL) para a API do ViaCEP.
///
/// Absorve as convenções e formatos da API externa sem permitir
/// que nomes como 'logradouro' ou 'localidade' vazem para o Domínio.
class ViaCepAddressDto {
  final String cep;
  final String logradouro;
  final String complemento;
  final String bairro;
  final String localidade;
  final String uf;
  final bool isError;

  const ViaCepAddressDto({
    required this.cep,
    required this.logradouro,
    required this.complemento,
    required this.bairro,
    required this.localidade,
    required this.uf,
    this.isError = false,
  });

  factory ViaCepAddressDto.fromJson(Map<String, dynamic> json) {
    final hasError = json['erro'] == true || json['erro'] == 'true';
    return ViaCepAddressDto(
      cep: (json['cep'] as String?) ?? '',
      logradouro: (json['logradouro'] as String?) ?? '',
      complemento: (json['complemento'] as String?) ?? '',
      bairro: (json['bairro'] as String?) ?? '',
      localidade: (json['localidade'] as String?) ?? '',
      uf: (json['uf'] as String?) ?? '',
      isError: hasError,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cep': cep,
      'logradouro': logradouro,
      'complemento': complemento,
      'bairro': bairro,
      'localidade': localidade,
      'uf': uf,
      'erro': isError,
    };
  }

  /// Mapeia os dados externos para a Entidade Pura do Domínio.
  Address toDomain() {
    return Address(
      cep: cep.replaceAll(RegExp(r'\D'), ''),
      street: logradouro,
      complement: complemento,
      neighborhood: bairro,
      city: localidade,
      state: uf,
    );
  }
}
