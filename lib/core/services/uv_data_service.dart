import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';

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
    final uvValue = json['uv_index'] ?? json['uvIndex'] ?? json['indiceUV'] ?? 0;
    return UVData(
      uvIndex: (uvValue is num) ? uvValue.toDouble() : 0.0,
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

  /// Busca dados UV do dispositivo (mDNS com fallback para IP fixo)
  static Future<UVData> fetchUVData() async {
    final urls = _useFallbackIp
        ? [_getFallbackUrl(), _getMdnsUrl()]
        : [_getMdnsUrl(), _getFallbackUrl()];

    Exception? lastError;

    for (final url in urls) {
      try {
        final response = await http
            .get(url, headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            })
            .timeout(AppConstants.httpTimeout);

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          
          final data = UVData.fromJson(jsonResponse);
          _cacheData(data);
          
          // Memoriza URL que funcionou
          _useFallbackIp = url.toString().contains(AppConstants.deviceFallbackIp);
          
          return data;
        } else {
          lastError = UVDataException(
            AppStrings.failedToLoadUVData,
            statusCode: response.statusCode,
          );
        }
      } catch (e) {
        debugPrint('Falha ao buscar de $url: $e');
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
    return Uri.parse('${AppConstants.deviceBaseUrl}${AppConstants.deviceDataEndpoint}');
  }

  static Uri _getFallbackUrl() {
    return Uri.parse('http://${AppConstants.deviceFallbackIp}${AppConstants.deviceDataEndpoint}');
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
        final response = await http
            .get(url)
            .timeout(AppConstants.connectionCheckTimeout);

        if (response.statusCode == 200) {
          _useFallbackIp = url.toString().contains(AppConstants.deviceFallbackIp);
          debugPrint('UVDataService: dispositivo acessível via $url');
          return true;
        } else {
          debugPrint(
            'UVDataService: $url respondeu com status ${response.statusCode}',
          );
        }
      } on TimeoutException {
        debugPrint(
          'UVDataService: timeout ao verificar $url '
          '(${AppConstants.connectionCheckTimeout.inSeconds}s)',
        );
      } on http.ClientException catch (e) {
        debugPrint('UVDataService: erro de cliente HTTP em $url: ${e.message}');
      } on FormatException catch (e) {
        debugPrint('UVDataService: URL malformada $url: ${e.message}');
      } catch (e) {
        debugPrint('UVDataService: erro inesperado ao verificar $url: $e');
      }
    }

    debugPrint('UVDataService: dispositivo inacessível em todas as URLs');
    return false;
  }

  /// Limpa o cache em memória
  static void clearCache() {
    _cachedData = null;
    _cacheTime = null;
  }

  /// Reseta a preferência de URL (volta a tentar mDNS primeiro)  static void resetUrlPreference() {
    _useFallbackIp = false;
  }
}
