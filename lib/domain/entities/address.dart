/// Entidade de domínio pura para endereço, totalmente desacoplada de fornecedores externos como ViaCEP.
class Address {
  final String cep;
  final String street;
  final String complement;
  final String neighborhood;
  final String city;
  final String state;

  const Address({
    required this.cep,
    required this.street,
    this.complement = '',
    required this.neighborhood,
    required this.city,
    required this.state,
  });

  /// Retorna o endereço formatado em uma única linha legível.
  String get formattedOneLine {
    final parts = [street, complement, neighborhood, city, state].where((p) => p.isNotEmpty);
    return parts.join(', ');
  }

  Address copyWith({
    String? cep,
    String? street,
    String? complement,
    String? neighborhood,
    String? city,
    String? state,
  }) {
    return Address(
      cep: cep ?? this.cep,
      street: street ?? this.street,
      complement: complement ?? this.complement,
      neighborhood: neighborhood ?? this.neighborhood,
      city: city ?? this.city,
      state: state ?? this.state,
    );
  }
}
