/// Utilitários compartilhados para setUp de testes.
///
/// Centraliza inicialização de mocks, MethodChannels e serviços
/// para evitar duplicação entre categorias de teste.
library;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uv_exposure_app/core/services/storage_service.dart';

/// Inicializa o binding de testes e os mocks de MethodChannel
/// necessários para audioplayers e notificações locais.
void initTestEnvironment() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel audioChannel = MethodChannel('xyz.luan/audioplayers');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(audioChannel, (MethodCall methodCall) async {
    return null;
  });

  const MethodChannel notificationsChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(notificationsChannel,
          (MethodCall methodCall) async {
    return null;
  });
}

/// Reseta e inicializa StorageService com SharedPreferences mockadas.
/// [extras] permite injetar valores iniciais adicionais.
Future<void> initTestStorage({Map<String, Object> extras = const {}}) async {
  StorageService.resetForTest();
  SharedPreferences.setMockInitialValues({
    'notification_permission_asked': true,
    ...extras,
  });
  await StorageService.init();
}
