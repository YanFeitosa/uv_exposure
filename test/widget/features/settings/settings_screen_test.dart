// Testes unitários — SettingsScreen (renderização)
//
// Cobre: renderização de título e switches.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uv_exposure_app/core/constants/app_strings.dart';
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

  group('SettingsScreen — renderização', () {
    testWidgets('deve exibir título e switches', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.settings), findsOneWidget);
      expect(find.text(AppStrings.soundAlarmLabel), findsOneWidget);
      expect(find.text(AppStrings.demoModeLabel), findsOneWidget);
    });
  });
}
