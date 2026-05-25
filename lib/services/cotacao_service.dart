import 'dart:convert';
import 'package:http/http.dart' as http;

class CotacaoService {
  Future<Map<String, dynamic>> buscarCotacoes() async {
    final response = await http.get(
      Uri.parse(
        'https://economia.awesomeapi.com.br/json/last/USD-BRL,EUR-BRL,BTC-BRL',
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao carregar cotações');
    }
  }
}