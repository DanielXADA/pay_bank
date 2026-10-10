import '../entities/address.dart';

/// Contrato para busca de endereço (Anti-Corruption Layer sobre serviços de CEP).
abstract class IAddressRepository {
  /// Busca dados de endereço a partir de um CEP e retorna uma entidade Address do domínio.
  Future<Address> getAddressByCep(String cep);
}
