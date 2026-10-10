import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/address.dart';
import '../../domain/repositories/i_address_repository.dart';
import '../datasources/remote/viacep_remote_datasource.dart';

class AddressRepositoryImpl implements IAddressRepository {
  final ViaCepRemoteDataSource _remoteDataSource;

  AddressRepositoryImpl({ViaCepRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? ViaCepRemoteDataSource();

  @override
  Future<Address> getAddressByCep(String cep) async {
    try {
      final dto = await _remoteDataSource.fetchAddressByCep(cep);
      // Anti-Corruption Layer: O DTO da API é transformado na Entidade Pura de Domínio
      return dto.toDomain();
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } on ExternalServiceException catch (e) {
      throw ExternalServiceFailure(e.message);
    } catch (e) {
      throw ExternalServiceFailure('Falha ao consultar endereço pelo CEP: $e');
    }
  }
}
