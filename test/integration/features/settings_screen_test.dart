/// Testes de integração — SettingsScreen
///
/// Cobre: alternância de preferências (demo mode, alarme) com persistência no StorageService.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uv_exposure_app/core/services/storage_service.dart';
import 'package:uv_exposure_app/features/settings/settings_screen.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    StorageService.resetForTest();
    SharedPreferences.setMockInitialValues({
      'notification_permission_asked': true,
    });
    await StorageService.init();
  });

  group('SettingsScreen — integração: persistência', () {
    testWidgets('deve alternar modo demo e persistir', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen()),
      );
      await tester.pumpAndSettle();

      final demoSwitch = find.byType(Switch).last;
      expect(demoSwitch, findsOneWidget);

      await tester.tap(demoSwitch);
      await tester.pumpAndSettle();

      final demoMode = await StorageService.getDemoMode();
      expect(demoMode, isTrue);
    });

    testWidgets('deve alternar alarme sonoro e persistir', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen()),
      );
      await tester.pumpAndSettle();

      final soundSwitch = find.byType(Switch).first;
      expect(soundSwitch, findsOneWidget);

      await tester.tap(soundSwitch);
      await tester.pumpAndSettle();

      final soundEnabled = await StorageService.isSoundAlarmEnabled();
      expect(soundEnabled, isFalse);
    });
  });
}
