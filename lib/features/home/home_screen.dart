import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/exposure_provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/storage_service.dart';
import '../monitor/monitor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _spfValue;
  String? _skinTypeValue;

  bool get _isButtonEnabled => _spfValue != null && _skinTypeValue != null;

  @override
  void initState() {
    super.initState();
    // Solicita permissão de notificação após o primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestNotificationPermission();
    });
  }

  Future<void> _requestNotificationPermission() async {
    if (kIsWeb) return;
    
    // Verifica se já tem permissão no sistema
    final hasPermission = await NotificationService.areNotificationsEnabled();
    if (hasPermission) {
      // Já tem permissão, não precisa perguntar
      return;
    }
    
    // Verifica se já perguntamos ao usuário antes
    final alreadyAsked = await StorageService.wasNotificationPermissionAsked();
    if (alreadyAsked) {
      // Já perguntamos, não incomodar novamente
      return;
    }
    
    // Aguarda um momento para o app carregar completamente
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    // Mostra diálogo explicando a importância das notificações
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.orange),
            SizedBox(width: 8),
            Text('Notificações'),
          ],
        ),
        content: const Text(
          'Para sua segurança, o SunSense precisa enviar notificações '
          'quando você atingir limites de exposição solar.\n\n'
          'Isso ajuda a proteger sua pele de queimaduras.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Depois'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Permitir'),
          ),
        ],
      ),
    );
    
    // Marca que já perguntamos (independente da resposta)
    await StorageService.setNotificationPermissionAsked();
    
    if (shouldRequest == true) {
      await NotificationService.requestPermission();
    }
  }

  void _startMonitoring() {
    if (!_isButtonEnabled) return;

    final provider = context.read<ExposureProvider>();
    provider.initialize(
      spf: double.parse(_spfValue!),
      skinType: _skinTypeValue!,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MonitorScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/history');
            },
            tooltip: AppStrings.exposureHistory,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.05),
                  
                  // Logo/Image
                  SizedBox(
                    height: screenHeight * 0.35,
                    child: Image.asset(
                      'assets/images/image.png',
                      width: screenWidth * 0.80,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.wb_sunny,
                          size: screenWidth * 0.4,
                          color: AppColors.primary,
                        );
                      },
                    ),
                  ),
                  
                  SizedBox(height: screenHeight * 0.03),
                  
                  // SPF Dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: AppStrings.spfLabel,
                      prefixIcon: Icon(Icons.shield),
                    ),
                    value: _spfValue,
                    items: AppStrings.spfValues.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text('SPF $value'),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _spfValue = newValue;
                      });
                    },
                  ),
                  
                  SizedBox(height: screenHeight * 0.03),
                  
                  // Skin Type Dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: AppStrings.skinTypeLabel,
                      prefixIcon: Icon(Icons.person),
                    ),
                    value: _skinTypeValue,
                    items: AppStrings.skinTypes.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _skinTypeValue = newValue;
                      });
                    },
                  ),
                  
                  SizedBox(height: screenHeight * 0.05),
                  
                  // Start Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isButtonEnabled ? _startMonitoring : null,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text(AppStrings.startMonitoring),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isButtonEnabled 
                            ? AppColors.secondary 
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: screenHeight * 0.03),
                  
                  // Info Card
                  Card(
                    color: AppColors.primary.withOpacity(0.2),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Make sure your phone is connected to the same WiFi network as the SunSense device.',
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
