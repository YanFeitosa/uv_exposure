/// Testes de falha e resiliência — UVDataService
///
/// Cobre: fallback para cache, erros HTTP (500, 404), timeout,
/// erros de rede em isDeviceReachable.
@Tags(['failure', 'timeout', 'fallback', 'recovery'])
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:uv_exposure_app/core/services/uv_data_service.dart';

class MockHttpClient extends Mock implements http.Client {}

class FakeUri extends Fake implements Uri {}

void main() {
  late MockHttpClient mockClient;

  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  setUp(() {
    mockClient = MockHttpClient();
    UVDataService.setHttpClient(mockClient);
    UVDataService.clearCache();
    UVDataService.resetUrlPreference();
  });

  tearDown(() {
    UVDataService.restoreHttpClient();
  });

  http.Response jsonResponse(Map<String, dynamic> body,
      {int statusCode = 200}) {
    return http.Response(jsonEncode(body), statusCode);
  }

  group('fetchUVData — fallback para cache', () {
    test('deve retornar cache quando ambas URLs falham', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => jsonResponse({'uv_index': 6.0}));
      await UVDataService.fetchUVData();

      reset(mockClient);
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(http.ClientException('Network error'));

      final data = await UVDataService.fetchUVData();
      expect(data.uvIndex, equals(6.0));
      expect(data.isFromCache, isTrue);
    });

    test('deve lançar UVDataException quando tudo falha e sem cache', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(http.ClientException('Network error'));

      expect(
        () => UVDataService.fetchUVData(),
        throwsA(isA<UVDataException>()),
      );
    });
  });

  group('fetchUVData — erros HTTP', () {
    test('deve tratar status 500 como falha', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Server Error', 500));

      expect(
        () => UVDataService.fetchUVData(),
        throwsA(isA<UVDataException>()),
      );
    });

    test('deve tratar status 404 como falha', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      expect(
        () => UVDataService.fetchUVData(),
        throwsA(isA<UVDataException>()),
      );
    });

    test('deve tratar timeout como falha', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async {
        throw TimeoutException('Connection timed out');
      });

      expect(
        () => UVDataService.fetchUVData(),
        throwsA(isA<UVDataException>()),
      );
    });
  });

  group('isDeviceReachable — falha', () {
    test('deve retornar false em timeout', () async {
      when(() => mockClient.get(any())).thenAnswer((_) async {
        throw TimeoutException('timeout');
      });
      final reachable = await UVDataService.isDeviceReachable();
      expect(reachable, isFalse);
    });

    test('deve retornar false em erro de rede', () async {
      when(() => mockClient.get(any()))
          .thenThrow(http.ClientException('No route'));
      final reachable = await UVDataService.isDeviceReachable();
      expect(reachable, isFalse);
    });
  });
}
