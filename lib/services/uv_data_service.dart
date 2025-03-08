import 'dart:convert'; // Importa o pacote para manipulação de JSON
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Importa o pacote http

Future<Map<String, dynamic>> fetchUVData() async {
  // URL do servidor ESP8266 com mDNS
  final url = Uri.parse('http://192.168.4.1/uvdata');

  try {
    // Faz a requisição GET
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
    });

    // Verifica se a resposta foi bem-sucedida
    if (response.statusCode == 200) {
      // Decodifica o JSON
      final jsonResponse = json.decode(response.body);
      debugPrint('UV data: $jsonResponse');
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
