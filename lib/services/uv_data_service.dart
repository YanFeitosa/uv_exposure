// Adicione a lógica para interação com o Bluetooth aqui
import 'dart:convert'; // Importa o pacote para manipulação de JSON
import 'package:http/http.dart' as http; // Importa o pacote http

Future<Map<String, dynamic>> fetchUVData() async {
  // URL do servidor ESP8266 com mDNS
  final url = Uri.parse('http://esp8266.local/uvdata');

  try {
    // Faz a requisição GET
    final response = await http.get(url);

    // Verifica se a resposta foi bem-sucedida
    if (response.statusCode == 200) {
      // Decodifica o JSON
      final jsonResponse = json.decode(response.body);
      return jsonResponse;
    } else {
      // Se a resposta não foi bem-sucedida, lança uma exceção
      throw Exception('Failed to load UV data');
    }
  } catch (e) {
    // Trata erros de rede ou de requisição
    rethrow; // Re-lança a exceção para que possa ser tratada no chamador
  }
}
