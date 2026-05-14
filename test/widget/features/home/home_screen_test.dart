// Testes unitários — HomeScreen (renderização, popup, sessão pendente)
//
// Cobre: renderização de elementos visuais, popup de configuração,
// diálogo de sessão pendente.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uv_exposure_app/core/constants/app_colors.dart';
import 'package:uv_exposure_app/core/constants/app_strings.dart';
import 'package:uv_exposure_app/core/providers/exposure_provider.dart';
import 'package:uv_exposure_app/core/services/notification_service.dart';
import 'package:uv_exposure_app/core/providers/history_provider.dart';
import 'package:uv_exposure_app/core/services/storage_service.dart';
import 'package:uv_exposure_app/features/home/home_screen.dart';

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
    NotificationService.initForTest();
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  Widget buildHomeScreen() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExposureProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: const MaterialApp(home: HomeScreen()),
    );
  }

  group('HomeScreen — renderização', () {
    testWidgets('deve exibir título, botão e card WiFi', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text(AppStrings.appTitle), findsOneWidget);
      expect(find.text(AppStrings.startMonitoring), findsOneWidget);
      expect(find.text(AppStrings.wifiInfoMessage), findsOneWidget);
    });

    testWidgets('deve exibir menu hamburguer com itens de navegação',
        (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byIcon(Icons.menu), findsOneWidget);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.history), findsWidgets);
      expect(find.byIcon(Icons.settings), findsWidgets);
      expect(find.byIcon(Icons.info_outline), findsWidgets);
      expect(find.text(AppStrings.exposureHistory), findsOneWidget);
      expect(find.text(AppStrings.settings), findsOneWidget);
      expect(find.text(AppStrings.about), findsOneWidget);
    });

    testWidgets('itens do drawer devem respeitar a ordem solicitada',
        (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      final historyY =
          tester.getTopLeft(find.text(AppStrings.exposureHistory)).dy;
      final settingsY = tester.getTopLeft(find.text(AppStrings.settings)).dy;
      final aboutY = tester.getTopLeft(find.text(AppStrings.about)).dy;

      expect(historyY, lessThan(settingsY));
      expect(settingsY, lessThan(aboutY));
    });

    testWidgets('AppBar deve exibir apenas o menu hamburguer', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsNothing);
      expect(find.byIcon(Icons.history), findsNothing);
      expect(find.byTooltip(AppStrings.about), findsNothing);
    });
  });

  group('HomeScreen — popup monitoramento', () {
    testWidgets('botão iniciar deve abrir popup de configuração',
        (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.text(AppStrings.startMonitoring));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.sessionConfigTitle), findsOneWidget);
      expect(find.text(AppStrings.skinTypeLabel), findsOneWidget);
      expect(find.text(AppStrings.spfLabel), findsOneWidget);
      expect(find.text(AppStrings.cancel), findsOneWidget);
      expect(find.text(AppStrings.start), findsOneWidget);
    });

    testWidgets('botão Iniciar desabilitado sem seleção', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.text(AppStrings.startMonitoring));
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, AppStrings.start),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('cancelar deve fechar popup', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.text(AppStrings.startMonitoring));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.sessionConfigTitle), findsNothing);
    });

    testWidgets('não mostrar Demo quando demoMode off', (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.text(AppStrings.startMonitoring));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      expect(find.text('Tipo 0 - Demo'), findsNothing);
      expect(find.text('Tipo II - Clara'), findsWidgets);
    });

    testWidgets('mostrar tipo Demo quando demoMode ativado', (tester) async {
      await StorageService.setDemoMode(true);

      await tester.pumpWidget(buildHomeScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.text(AppStrings.startMonitoring));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      expect(find.text('Tipo 0 - Demo'), findsWidgets);
    });

    testWidgets('dropdown de fototipo deve exibir indicador de cor',
        (tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.text(AppStrings.startMonitoring));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();

      final skinTypeColorFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            widget.icon == Icons.circle &&
            widget.color == AppColors.getSkinTypeColor('Tipo II - Clara'),
      );

      expect(skinTypeColorFinder, findsWidgets);
    });

    testWidgets('deve pré-selecionar último fototipo usado', (tester) async {
      await StorageService.saveUserPreferences(
          defaultSkinType: 'Tipo III - Média Clara');

      await tester.pumpWidget(buildHomeScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.text(AppStrings.startMonitoring));
      await tester.pumpAndSettle();
      expect(find.text('Tipo III - Média Clara'), findsOneWidget);
    });
  });

  group('HomeScreen — sessão pendente', () {
    testWidgets('deve mostrar diálogo de restauração para sessão salva',
        (tester) async {
      await StorageService.saveLastSession(
        spf: 30,
        skinType: 'Tipo II - Clara',
        accumulatedExposure: 25.5,
        secondsElapsed: 300,
      );

      await tester.pumpWidget(buildHomeScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.text('Sessão Anterior Encontrada'), findsOneWidget);
      expect(find.textContaining('Tipo II - Clara'), findsOneWidget);
      expect(find.textContaining('25.5%'), findsOneWidget);
      expect(find.text('Descartar'), findsOneWidget);
      expect(find.text('Restaurar'), findsOneWidget);
    });

    testWidgets('deve exibir SPF=0 como sem protetor solar no diálogo',
        (tester) async {
      await StorageService.saveLastSession(
        spf: 0,
        skinType: 'Tipo V - Escura',
        accumulatedExposure: 50.0,
        secondsElapsed: 180,
      );

      await tester.pumpWidget(buildHomeScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.textContaining('Tipo V - Escura'), findsOneWidget);
      expect(find.textContaining(AppStrings.noSunscreen), findsOneWidget);
      expect(find.textContaining('50.0%'), findsOneWidget);
      expect(find.textContaining('3m 0s'), findsOneWidget);
    });
  });
}
