import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/errors/exceptions.dart';
import '../../models/viacep_address_dto.dart';

class ViaCepRemoteDataSource {
  final http.Client _client;

  ViaCepRemoteDataSource({http.Client? client}) : _client = client ?? http.Client();

  /// Consulta os dados de endereço na API pública do ViaCEP com timeout e proteção de rede.
  Future<ViaCepAddressDto> fetchAddressByCep(String cep) async {
    final sanitizedCep = cep.replaceAll(RegExp(r'\D'), '');
    if (sanitizedCep.length != 8) {
      throw const ExternalServiceException('CEP inválido. Deve conter exatamente 8 dígitos.');
    }

    final url = Uri.parse('https://viacep.com.br/ws/$sanitizedCep/json/');

    try {
      final response = await _client.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['erro'] == true || data['erro'] == 'true') {
          throw const ExternalServiceException('CEP não localizado no diretório postal.');
        }

        return ViaCepAddressDto.fromJson(data);
      } else {
        throw ServerException('Servidor ViaCEP retornou status ${response.statusCode}');
      }
    } on SocketException {
      throw const NetworkException('Sem conexão com a internet para buscar o CEP.');
    } on TimeoutException {
      throw const NetworkException('Tempo limite esgotado ao consultar o serviço de CEP.');
    } on http.ClientException {
      throw const NetworkException('Falha de conexão com o servidor ViaCEP.');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ExternalServiceException('Erro inesperado ao consultar CEP: $e');
    }
  }
}
