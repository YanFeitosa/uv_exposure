import 'dart:async';
import 'package:flutter/material.dart';

class MonitorScreen extends StatefulWidget {
  final double spf;
  final String skinType;

  const MonitorScreen({super.key, required this.spf, required this.skinType});

  @override
  _MonitorScreenState createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  late Timer _timer;
  int _secondsElapsed = 0;
  late int _safeExposureTime; // Tempo seguro de exposição em segundos

  @override
  void initState() {
    super.initState();
    _safeExposureTime =
        _calculateSafeExposureTime(); // Calcular o tempo seguro com base no FPS e no tipo de pele
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  // Função para calcular o tempo seguro com base no FPS e tipo de pele
  int _calculateSafeExposureTime() {
    double baseTime = 45 * 60; // 45 minutos em segundos

    if (widget.spf == 15) {
      baseTime *= 0.75;
    } else if (widget.spf == 30) {
      baseTime *= 1.0;
    } else if (widget.spf == 50) {
      baseTime *= 1.25;
    }

    // Ajuste de tempo com base no tipo de pele
    switch (widget.skinType) {
      case 'Tipo I - Muito clara':
        baseTime *= 0.5;
        break;
      case 'Tipo II - Clara':
        baseTime *= 0.6;
        break;
      case 'Tipo III - Média Clara':
        baseTime *= 0.7;
        break;
      case 'Tipo IV - Média Escura':
        baseTime *= 0.8;
        break;
      case 'Tipo V - Escura':
        baseTime *= 0.9;
        break;
      case 'Tipo VI - Muito Escura':
        baseTime *= 1.0;
        break;
    }

    return baseTime.toInt();
  }

  Color _getColorForTime(int seconds) {
    if (seconds <= _safeExposureTime / 2) {
      return Color.lerp(
          Colors.green, Colors.yellow, seconds / (_safeExposureTime / 2))!;
    } else {
      return Color.lerp(Colors.yellow, Colors.red,
          (seconds - (_safeExposureTime / 2)) / (_safeExposureTime / 2))!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(
                    16), // Espaçamento interno do quadrado roxo
                decoration: BoxDecoration(
                  color: const Color(0xFF77347A), // Cor do quadrado roxo
                  borderRadius: BorderRadius.circular(
                      16), // Borda arredondada do quadrado roxo
                ),
                child: Column(
                  children: [
                    const Text(
                      'Tempo de Exposição',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors
                            .white, // Cor branca para o texto dentro do quadrado roxo
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment
                          .spaceBetween, // Espaço uniforme entre as colunas
                      children: [
                        // Quadrado branco envolvendo o "Total"
                        Container(
                          padding: const EdgeInsets.all(
                              16), // Espaçamento interno do quadrado branco
                          decoration: BoxDecoration(
                            color: Colors.white, // Cor do quadrado branco
                            borderRadius: BorderRadius.circular(
                                16), // Borda arredondada do quadrado branco
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatTime(_secondsElapsed),
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: _getColorForTime(_secondsElapsed),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Quadrado branco envolvendo o "Seguro"
                        Container(
                          padding: const EdgeInsets.all(
                              16), // Espaçamento interno do quadrado branco
                          decoration: BoxDecoration(
                            color: Colors.white, // Cor do quadrado branco
                            borderRadius: BorderRadius.circular(
                                16), // Borda arredondada do quadrado branco
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Seguro',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatTime(
                                    _safeExposureTime), // Tempo seguro calculado
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors
                                      .red, // Mantém vermelho como cor fixa
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Índice UV Atual',
                hintText: 'Insira o índice UV atual',
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
