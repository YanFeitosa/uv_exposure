import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'monitor_screen.dart'; // Importando MonitorScreen

// Variáveis globais para armazenar os valores selecionados
String? selectedSpf;
String? selectedSkinType;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? spfValue;
  String? skinTypeValue;

  bool get isButtonEnabled => spfValue != null && skinTypeValue != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFCE26), // Cor amarela para a AppBar
        title: const Center(
          child: Text(
            'UV Monitoramento',
            style: TextStyle(
              fontSize: 22, // Fonte levemente maior
              fontWeight: FontWeight.w800, // Negrito acentuado
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/logo.svg', // Caminho para a imagem SVG
              height: 400, // Altura ajustada
              width: 400, // Largura ajustada
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Fator de Proteção Solar (FPS)',
              ),
              items: <String>['15', '30', '50', '70'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  spfValue = newValue;
                });
              },
            ),
            const SizedBox(height: 32),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Fototipo de Pele',
              ),
              items: <String>[
                'Tipo I - Muito clara',
                'Tipo II - Clara',
                'Tipo III - Média Clara',
                'Tipo IV - Média Escura',
                'Tipo V - Escura',
                'Tipo VI - Muito Escura'
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  skinTypeValue = newValue;
                });
              },
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: isButtonEnabled
                  ? () {
                      // Navegar para MonitorScreen passando os parâmetros
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MonitorScreen(
                            spf: double.parse(spfValue!), // Passando o SPF
                            skinType: skinTypeValue!, // Passando o tipo de pele
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isButtonEnabled ? const Color(0xFF77347A) : null,
                side: BorderSide(
                  color: isButtonEnabled
                      ? const Color(0xFF77347A)
                      : const Color(0xFF77347A),
                  width: 2,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Iniciar Monitoramento',
                style: TextStyle(
                  color: isButtonEnabled
                      ? const Color.fromARGB(255, 255, 255, 255)
                      : const Color(0xFF77347A),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
