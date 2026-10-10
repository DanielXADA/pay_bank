import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/currency_quote.dart';
import '../../domain/repositories/i_currency_repository.dart';
import '../datasources/remote/awesome_api_remote_datasource.dart';

class CurrencyRepositoryImpl implements ICurrencyRepository {
  final AwesomeApiRemoteDataSource _remoteDataSource;

  CurrencyRepositoryImpl({AwesomeApiRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? AwesomeApiRemoteDataSource();

  @override
  Future<List<CurrencyQuote>> getRealTimeQuotes() async {
    try {
      final dtos = await _remoteDataSource.fetchRealTimeQuotes();
      // Anti-Corruption Layer: Isola completamente o formato JSON da AwesomeAPI
      return dtos.map((dto) => dto.toDomain()).toList();
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } on ExternalServiceException catch (e) {
      throw ExternalServiceFailure(e.message);
    } catch (e) {
      throw ExternalServiceFailure('Falha ao obter cotações cambiais: $e');
    }
  }
}
