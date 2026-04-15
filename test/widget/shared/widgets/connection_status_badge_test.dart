/// Testes unitários — ConnectionStatusBadge
///
/// Cobre: exibição de estados de conexão (offline, connected, connecting, cache).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uv_exposure_app/core/providers/exposure_provider.dart';
import 'package:uv_exposure_app/core/services/storage_service.dart';
import 'package:uv_exposure_app/shared/widgets/connection_status_badge.dart';
import 'package:uv_exposure_app/core/constants/app_strings.dart';

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

  Widget buildBadge(ExposureProvider provider) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        home: Scaffold(body: ConnectionStatusBadge()),
      ),
    );
  }

  group('ConnectionStatusBadge', () {
    testWidgets('deve exibir "Desconectado" no estado inicial',
        (tester) async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');

      await tester.pumpWidget(buildBadge(provider));
      await tester.pump();

      expect(find.text(AppStrings.offline), findsOneWidget);
    });

    testWidgets('deve exibir "Conectado" em modo demo', (tester) async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setDemoMode(true);
      await provider.startMonitoring();

      await tester.pumpWidget(buildBadge(provider));
      await tester.pump();

      expect(find.text(AppStrings.connected), findsOneWidget);

      await provider.stopMonitoring();
    });

    testWidgets('deve exibir "Conectando" no estado connecting',
        (tester) async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setTestState(connectionStatus: ConnectionStatus.connecting);

      await tester.pumpWidget(buildBadge(provider));
      await tester.pump();

      expect(find.text(AppStrings.connecting), findsOneWidget);
    });

    testWidgets('deve exibir "Cache" no estado usingCache', (tester) async {
      final provider = ExposureProvider();
      provider.initialize(spf: 30, skinType: 'Tipo II - Clara');
      provider.setTestState(connectionStatus: ConnectionStatus.usingCache);

      await tester.pumpWidget(buildBadge(provider));
      await tester.pump();

      expect(find.text(AppStrings.cached), findsOneWidget);
    });
  });
}
