import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/providers/exposure_provider.dart';
import 'core/providers/history_provider.dart';
import 'core/services/logger_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'features/home/home_screen.dart';
import 'features/history/history_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/about/about_screen.dart';
import 'features/monitor/monitor_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa serviços essenciais
  try {
    await StorageService.init();
  } catch (e) {
    LoggerService.error('Falha ao inicializar StorageService',
        tag: 'Main', error: e);
  }

  // Inicializa notificações (permissão será pedida na HomeScreen)
  if (!kIsWeb) {
    try {
      await NotificationService.init();
    } catch (e) {
      LoggerService.error('Falha ao inicializar NotificationService',
          tag: 'Main', error: e);
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
          '/monitor': (context) => const MonitorScreen(),
          '/history': (context) => const HistoryScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/about': (context) => const AboutScreen(),
        },
      ),
    );
  }
}
