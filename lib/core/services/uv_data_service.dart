import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

/// Dados UV recebidos do dispositivo
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
    // Chave correta do dispositivo SunSense: uv_index
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

/// Exceção customizada para erros relacionados aos dados UV.
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

/// Serviço para buscar dados UV do dispositivo SunSense.
/// 
/// O dispositivo deve estar conectado à mesma rede WiFi que o celular.
/// Os dados são disponibilizados via mDNS no endpoint http://sunsense.local/data
class UVDataService {
  static UVData? _cachedData;
  static DateTime? _cacheTime;
  static bool _useFallbackIp = false;

  /// Busca os dados UV do dispositivo SunSense.
  /// 
  /// Tenta primeiro via mDNS (sunsense.local), e em caso de falha,
  /// tenta usar o IP de fallback configurado.
  static Future<UVData> fetchUVData() async {
    // Tenta mDNS primeiro, depois fallback IP se necessário
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
          // debugPrint('UV data received from $url: $jsonResponse');
          
          final data = UVData.fromJson(jsonResponse);
          _cacheData(data);
          
          // Lembra qual URL funcionou
          _useFallbackIp = url.toString().contains(AppConstants.deviceFallbackIp);
          
          return data;
        } else {
          lastError = UVDataException(
            'Failed to load UV data',
            statusCode: response.statusCode,
          );
        }
      } catch (e) {
        debugPrint('Failed to fetch from $url: $e');
        lastError = e is Exception ? e : Exception(e.toString());
      }
    }

    // Se falhou em ambos, verifica cache
    final cached = getCachedData();
    if (cached != null) {
      // debugPrint('Using cached UV data');
      return cached.copyWithCache();
    }

    throw UVDataException(
      'Network error: Unable to connect to SunSense device. '
      'Make sure you are connected to the same WiFi network.',
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

  /// Retorna dados do cache se ainda válidos
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

  /// Verifica se o dispositivo SunSense está acessível na rede.
  static Future<bool> isDeviceReachable() async {
    try {
      final urls = [_getMdnsUrl(), _getFallbackUrl()];
      
      for (final url in urls) {
        try {
          final response = await http
              .get(url)
              .timeout(AppConstants.connectionCheckTimeout);
          
          if (response.statusCode == 200) {
            _useFallbackIp = url.toString().contains(AppConstants.deviceFallbackIp);
            return true;
          }
        } catch (_) {
          continue;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Limpa o cache
  static void clearCache() {
    _cachedData = null;
    _cacheTime = null;
  }

  /// Reseta a preferência de URL
  static void resetUrlPreference() {
    _useFallbackIp = false;
  }
}
