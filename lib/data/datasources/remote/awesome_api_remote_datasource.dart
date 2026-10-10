import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/errors/exceptions.dart';
import '../../models/awesome_currency_dto.dart';

class AwesomeApiRemoteDataSource {
  final http.Client _client;

  AwesomeApiRemoteDataSource({http.Client? client}) : _client = client ?? http.Client();

  /// Busca as cotações das principais moedas (USD, EUR, BTC) em tempo real contra o Real (BRL).
  Future<List<AwesomeCurrencyDto>> fetchRealTimeQuotes() async {
    final url = Uri.parse(
      'https://economia.awesomeapi.com.br/json/last/USD-BRL,EUR-BRL,BTC-BRL',
    );

    try {
      final response = await _client.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<AwesomeCurrencyDto> quotes = [];

        data.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            quotes.add(AwesomeCurrencyDto.fromJson(value));
          }
        });

        return quotes;
      } else {
        throw ServerException('Serviço de cotações retornou status ${response.statusCode}');
      }
    } on SocketException {
      throw const NetworkException('Sem conexão com a internet para atualizar as cotações.');
    } on TimeoutException {
      throw const NetworkException('Tempo limite esgotado ao buscar cotações em tempo real.');
    } on http.ClientException {
      throw const NetworkException('Falha de conexão com a API de câmbio.');
    } on AppException {
      rethrow;
    } catch (e) {
      throw ExternalServiceException('Erro inesperado ao consultar cotações: $e');
    }
  }
}
