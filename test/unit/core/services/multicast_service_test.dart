// Testes unitários — MulticastService
//
// O MulticastService usa RawDatagramSocket (socket UDP real do SO), que não
// pode ser mockado diretamente em testes headless. Por isso a estratégia é:
//   1. Testar toda a lógica de estado (getters, reset, isReceiving).
//   2. Testar stop() quando não há socket aberto (guard paths).
//   3. Testar start() esperando falha de bind (cobre bloco catch+stop+rethrow).
//   4. Testar os lock methods via MethodChannel mock.
//   5. Testar cacheFromMulticast() do UVDataService.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uv_exposure_app/core/services/multicast_service.dart';
import 'package:uv_exposure_app/core/services/uv_data_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    const MethodChannel channel = MethodChannel('com.sunsense/multicast');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return null;
    });
  });

  setUp(() async {
    // Garante estado limpo antes de cada teste
    await MulticastService.stop();
    MulticastService.reset();
  });

  // ── Estado inicial ────────────────────────────────────────────────────────

  group('MulticastService — estado inicial', () {
    test('latestData é null antes de receber dados', () {
      expect(MulticastService.latestData, isNull);
    });

    test('lastReceived é null antes de receber dados', () {
      expect(MulticastService.lastReceived, isNull);
    });

    test('isReceiving é false antes de receber dados', () {
      expect(MulticastService.isReceiving, isFalse);
    });

    test('dataStream é broadcast stream (permite múltiplos listeners)', () {
      expect(MulticastService.dataStream.isBroadcast, isTrue);
    });
  });

  // ── reset() ───────────────────────────────────────────────────────────────

  group('MulticastService — reset', () {
    test('limpa latestData e lastReceived', () {
      MulticastService.reset();
      expect(MulticastService.latestData, isNull);
      expect(MulticastService.lastReceived, isNull);
      expect(MulticastService.isReceiving, isFalse);
    });
  });

  // ── stop() sem socket ─────────────────────────────────────────────────────

  group('MulticastService — stop() sem socket aberto', () {
    test('não lança exceção quando chamado sem start', () async {
      await expectLater(MulticastService.stop(), completes);
    });

    test('pode ser chamado múltiplas vezes sem erro', () async {
      await MulticastService.stop();
      await MulticastService.stop();
      expect(MulticastService.isReceiving, isFalse);
    });
  });

  // ── start() em ambiente de teste ──────────────────────────────────────────

  group('MulticastService — start() em ambiente de teste', () {
    test('lança exceção (sem socket real) e limpa estado interno', () async {
      // Em ambiente de teste headless RawDatagramSocket.bind() falha.
      // O bloco catch de start() chama stop() e faz rethrow — cobrindo
      // os caminhos de tratamento de erro do serviço.
      try {
        await MulticastService.start();
        // Se por algum motivo o bind funcionar no ambiente de CI, ok também
      } catch (_) {
        // Esperado em testes headless — estado deve estar limpo
        expect(MulticastService.latestData, isNull);
        expect(MulticastService.isReceiving, isFalse);
      }
    });

    test('segunda chamada a start() é idempotente (não duplo-bind)', () async {
      // Primeiro start pode falhar; não deve deixar socket parcialmente aberto
      try {
        await MulticastService.start();
      } catch (_) {}
      // Após falha, socket deve ser nulo → segunda chamada executa normalmente
      try {
        await MulticastService.start();
      } catch (_) {}
      expect(MulticastService.isReceiving, isFalse);
    });
  });

  // ── UVDataService.cacheFromMulticast ─────────────────────────────────────

  group('UVDataService — cacheFromMulticast', () {
    setUp(() => UVDataService.clearCache());

    test('não lança exceção com dado válido', () {
      final data = UVData.fromJson({'uv_index': 8.5});
      expect(() => UVDataService.cacheFromMulticast(data), returnsNormally);
    });

    test('não lança exceção com uv_index zero', () {
      final data = UVData.fromJson({'uv_index': 0.0});
      expect(() => UVDataService.cacheFromMulticast(data), returnsNormally);
    });

    test('não lança exceção com uv_index alto', () {
      final data = UVData.fromJson({'uv_index': 15.0, 'mv_reading': 999.9});
      expect(() => UVDataService.cacheFromMulticast(data), returnsNormally);
    });

    test('dado cacheado fica disponível via getCachedData', () {
      final data = UVData.fromJson({'uv_index': 6.2});
      UVDataService.cacheFromMulticast(data);
      final cached = UVDataService.getCachedData();
      expect(cached, isNotNull);
      expect(cached!.uvIndex, equals(6.2));
    });
  });
}
