import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import 'logger_service.dart';

/// Dados UV recebidos do dispositivo IoT
class UVData {
  final double uvIndex;
  final DateTime timestamp;
  final bool isFromCache;

  const UVData({
    required this.uvIndex,
    required this.timestamp,
    this.isFromCache = false,
  });

  factory UVData.fromJson(Map<String, dynamic> json) {
    // Aceita 'uv_index', 'uvIndex' e 'indiceUV'
    final uvValue = json['uv_index'] ?? json['uvIndex'] ?? json['indiceUV'];
    if (uvValue == null) {
      throw const UVDataException(
        'JSON não contém chave de índice UV válida (uv_index, uvIndex ou indiceUV)',
      );
    }
    if (uvValue is! num) {
      throw UVDataException(
        'Valor UV inválido: esperado numérico, recebido ${uvValue.runtimeType}',
      );
    }
    return UVData(
      uvIndex: uvValue.toDouble(),
      timestamp: DateTime.now(),
    );
  }

  UVData copyWithCache() {
    return UVData(
      uvIndex: uvIndex,
      timestamp: timestamp,
      isFromCache: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'uvIndex': uvIndex,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Exceção para erros na obtenção de dados UV
class UVDataException implements Exception {
  final String message;
  final int? statusCode;
  final Object? originalError;

  const UVDataException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() {
    if (statusCode != null) {
      return 'UVDataException: $message (Status: $statusCode)';
    }
    return 'UVDataException: $message';
  }
}

/// Serviço para buscar dados UV do dispositivo IoT SunSense
class UVDataService {
  static UVData? _cachedData;
  static DateTime? _cacheTime;
  static bool _useFallbackIp = false;

  /// Cliente HTTP injetável para permitir testes com mock.
  /// Em produção usa o cliente padrão; em testes, pode ser substituído.
  static http.Client _httpClient = http.Client();

  /// Substitui o cliente HTTP (usado em testes)
  static void setHttpClient(http.Client client) {
    _httpClient = client;
  }

  /// Restaura o cliente HTTP padrão
  static void restoreHttpClient() {
    _httpClient = http.Client();
  }

  /// Busca dados UV do dispositivo (mDNS com fallback para IP fixo)
  static Future<UVData> fetchUVData() async {
    final urls = _useFallbackIp
        ? [_getFallbackUrl(), _getMdnsUrl()]
        : [_getMdnsUrl(), _getFallbackUrl()];

    Exception? lastError;

    for (final url in urls) {
      try {
        final response = await _httpClient.get(url, headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }).timeout(AppConstants.httpTimeout);

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);

          final data = UVData.fromJson(jsonResponse);
          _cacheData(data);

          // Memoriza URL que funcionou
          _useFallbackIp =
              url.toString().contains(AppConstants.deviceFallbackIp);

          return data;
        } else {
          lastError = UVDataException(
            AppStrings.failedToLoadUVData,
            statusCode: response.statusCode,
          );
        }
      } catch (e) {
        AppLogger.warning('Falha ao buscar de $url',
            tag: 'UVDataService', error: e);
        lastError = e is Exception ? e : Exception(e.toString());
      }
    }

    // Fallback: cache em memória
    final cached = getCachedData();
    if (cached != null) {
      return cached.copyWithCache();
    }

    throw UVDataException(
      AppStrings.networkError,
      originalError: lastError,
    );
  }

  static Uri _getMdnsUrl() {
    return Uri.parse(
        '${AppConstants.deviceBaseUrl}${AppConstants.deviceDataEndpoint}');
  }

  static Uri _getFallbackUrl() {
    return Uri.parse(
        'http://${AppConstants.deviceFallbackIp}${AppConstants.deviceDataEndpoint}');
  }

  static void _cacheData(UVData data) {
    _cachedData = data;
    _cacheTime = DateTime.now();
  }

  /// Retorna dados do cache em memória se válidos
  static UVData? getCachedData() {
    if (_cachedData == null || _cacheTime == null) return null;

    final age = DateTime.now().difference(_cacheTime!);
    if (age > AppConstants.cacheExpiration) {
      _cachedData = null;
      _cacheTime = null;
      return null;
    }

    return _cachedData;
  }

  /// Verifica se o dispositivo SunSense está acessível na rede local
  static Future<bool> isDeviceReachable() async {
    final urls = [_getMdnsUrl(), _getFallbackUrl()];

    for (final url in urls) {
      try {
        final response = await _httpClient
            .get(url)
            .timeout(AppConstants.connectionCheckTimeout);

        if (response.statusCode == 200) {
          _useFallbackIp =
              url.toString().contains(AppConstants.deviceFallbackIp);
          AppLogger.info('Dispositivo acessível via $url',
              tag: 'UVDataService');
          return true;
        } else {
          AppLogger.warning(
            '$url respondeu com status ${response.statusCode}',
            tag: 'UVDataService',
          );
        }
      } on TimeoutException {
        AppLogger.warning(
          'Timeout ao verificar $url '
          '(${AppConstants.connectionCheckTimeout.inSeconds}s)',
          tag: 'UVDataService',
        );
      } on http.ClientException catch (e) {
        AppLogger.warning('Erro de cliente HTTP em $url: ${e.message}',
            tag: 'UVDataService');
      } on FormatException catch (e) {
        AppLogger.warning('URL malformada $url: ${e.message}',
            tag: 'UVDataService');
      } catch (e) {
        AppLogger.error('Erro inesperado ao verificar $url',
            tag: 'UVDataService', error: e);
      }
    }

    AppLogger.warning('Dispositivo inacessível em todas as URLs',
        tag: 'UVDataService');
    return false;
  }

  /// Limpa o cache em memória
  static void clearCache() {
    _cachedData = null;
    _cacheTime = null;
  }

  /// Reseta a preferência de URL (volta a tentar mDNS primeiro)
  static void resetUrlPreference() {
    _useFallbackIp = false;
  }

  /// Atualiza o cache em memória com dados vindos do multicast
  static void cacheFromMulticast(UVData data) {
    _cacheData(data);
  }
}
