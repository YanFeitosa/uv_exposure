import 'package:flutter/material.dart';
import 'monitor_screen.dart';

String? selectedSpf;
String? selectedSkinType;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? spfValue;
  String? skinTypeValue;

  @override
  void initState() {
    super.initState();
    // Resetar os valores ao inicializar o estado
    selectedSpf = null;
    selectedSkinType = null;
    spfValue = null;
    skinTypeValue = null;
  }

  bool get isButtonEnabled => spfValue != null && skinTypeValue != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFCE26),
        title: const Center(
          child: Text(
            'SUNSENSE',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/image.png',
              height: 400,
              width: 400,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Sun Protection Factor (SPF)',
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
                labelText: 'Skin Phototype',
              ),
              items: <String>[
                'Type 0 - Test',
                'Type I - Very Fair',
                'Type II - Fair',
                'Type III - Medium Fair',
                'Type IV - Medium Dark',
                'Type V - Dark',
                'Type VI - Very Dark'
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
                            spf: double.parse(spfValue!),
                            skinType: skinTypeValue!,
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
