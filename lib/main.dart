import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/providers/exposure_provider.dart';
import 'core/providers/history_provider.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'features/home/home_screen.dart';
import 'features/history/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa serviços com tratamento de erros
  try {
    await StorageService.init();
  } catch (e) {
    debugPrint('Erro ao inicializar StorageService: $e');
  }
  
  // Inicializa o serviço de notificações (apenas inicializa, não pede permissão ainda)
  // A permissão será solicitada na HomeScreen de forma amigável
  if (!kIsWeb) {
    try {
      await NotificationService.init();
    } catch (e) {
      debugPrint('Erro ao inicializar NotificationService: $e');
    }
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExposureProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/history': (context) => const HistoryScreen(),
        },
      ),
    );
  }
}
