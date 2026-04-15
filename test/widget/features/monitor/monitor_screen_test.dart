// Testes unitários — MonitorScreen (renderização, diálogos)
//
// Cobre: renderização de elementos visuais, banner demo, InfoBoxes,
// diálogos de confirmação (parar, voltar).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uv_exposure_app/core/constants/app_strings.dart';
import 'package:uv_exposure_app/core/providers/exposure_provider.dart';
import 'package:uv_exposure_app/core/services/storage_service.dart';
import 'package:uv_exposure_app/features/monitor/monitor_screen.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    const MethodChannel audioChannel = MethodChannel('xyz.luan/audioplayers');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, (MethodCall methodCall) async {
      return null;
    });
  });

  setUp(() async {
    StorageService.resetForTest();
    SharedPreferences.setMockInitialValues({
      'notification_permission_asked': true,
    });
    await StorageService.init();
  });

  Widget buildMonitorScreen(ExposureProvider provider) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(home: MonitorScreen()),
    );
  }

  group('MonitorScreen — renderização', () {
    testWidgets('deve exibir título do app e botão parar', (tester) async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await tester.pumpWidget(buildMonitorScreen(provider));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text(AppStrings.appTitle), findsOneWidget);
      expect(find.text(AppStrings.endMonitoring), findsOneWidget);

      await provider.stopMonitoring();
    });

    testWidgets('deve exibir banner de modo demo', (tester) async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await tester.pumpWidget(buildMonitorScreen(provider));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text(AppStrings.demoBannerText), findsOneWidget);
      await provider.stopMonitoring();
    });

    testWidgets('deve exibir InfoBoxes com métricas', (tester) async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await tester.pumpWidget(buildMonitorScreen(provider));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text(AppStrings.elapsedTime), findsOneWidget);
      expect(find.text(AppStrings.safeExposureTime), findsOneWidget);
      expect(find.text(AppStrings.accumulatedExposure), findsOneWidget);
      expect(find.text(AppStrings.globalUVIndex), findsOneWidget);

      await provider.stopMonitoring();
    });

    testWidgets('não deve exibir banner demo quando demo mode off',
        (tester) async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');

      await tester.pumpWidget(buildMonitorScreen(provider));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text(AppStrings.demoBannerText), findsNothing);
      await provider.stopMonitoring();
    });
  });

  group('MonitorScreen — diálogos', () {
    testWidgets('botão parar deve abrir diálogo de confirmação',
        (tester) async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await tester.pumpWidget(buildMonitorScreen(provider));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.scrollUntilVisible(find.text(AppStrings.endMonitoring), 200);
      await tester.tap(find.text(AppStrings.endMonitoring));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.confirm), findsWidgets);

      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();
      expect(provider.isMonitoring, isTrue);

      await provider.stopMonitoring();
    });

    testWidgets('back button deve abrir diálogo de confirmação',
        (tester) async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await tester.pumpWidget(buildMonitorScreen(provider));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.confirmBackMessage), findsOneWidget);
      expect(find.text(AppStrings.confirm), findsWidgets);
      expect(find.text(AppStrings.cancel), findsOneWidget);

      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.appTitle), findsOneWidget);

      await provider.stopMonitoring();
    });

    testWidgets('confirmar voltar deve parar monitoramento', (tester) async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);

      await tester.pumpWidget(buildMonitorScreen(provider));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.confirmBackMessage), findsOneWidget);

      await tester.tap(find.text(AppStrings.confirm).last);
      await tester.pumpAndSettle();
      expect(provider.isMonitoring, isFalse);
    });
  });
}
