import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import 'logger_service.dart';
import 'uv_data_service.dart';

/// Serviço de recepção UDP multicast para dados do sensor SunSense.
///
/// O dispositivo ESP envia JSON via multicast a cada 1 segundo no grupo
/// 239.255.0.1:5000. Este serviço escuta esses pacotes e expõe os dados
/// via [latestData] e [dataStream].
class MulticastService {
  static const _tag = 'MulticastService';
  static const _channel = MethodChannel('com.sunsense/multicast');

  static RawDatagramSocket? _socket;
  static StreamSubscription<RawSocketEvent>? _subscription;
  static StreamController<UVData> _controller =
      StreamController<UVData>.broadcast();
  static UVData? _latestData;
  static DateTime? _lastReceived;
  static bool _lockAcquired = false;

  /// Stream reativa de dados UV recebidos via multicast
  static Stream<UVData> get dataStream => _controller.stream;

  /// Último dado recebido via multicast (null se nunca recebeu)
  static UVData? get latestData => _latestData;

  /// Timestamp do último pacote recebido
  static DateTime? get lastReceived => _lastReceived;

  /// Verifica se o multicast está ativo e recebendo dados
  static bool get isReceiving {
    if (_lastReceived == null) return false;
    return DateTime.now().difference(_lastReceived!) <
        AppConstants.multicastTimeout;
  }

  /// Inicia a escuta UDP multicast.
  /// Adquire o MulticastLock no Android e faz bind no grupo.
  static Future<void> start() async {
    if (_socket != null) return;

    // Adquire MulticastLock no Android (necessário para receber multicast)
    await _acquireMulticastLock();

    try {
      final address = InternetAddress(AppConstants.multicastAddress);
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        AppConstants.multicastPort,
        reuseAddress: true,
        reusePort: true,
      );
      _socket!.joinMulticast(address);

      _subscription = _socket!.listen(_handleEvent);

      LoggerService.info(
        'Escutando multicast em ${AppConstants.multicastAddress}:'
        '${AppConstants.multicastPort}',
        tag: _tag,
      );
    } catch (e) {
      LoggerService.error('Falha ao iniciar multicast', tag: _tag, error: e);
      await stop();
      rethrow;
    }
  }

  /// Para a escuta multicast e libera recursos.
  static Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;

    if (_socket != null) {
      try {
        _socket!.leaveMulticast(
          InternetAddress(AppConstants.multicastAddress),
        );
      } catch (_) {}
      _socket!.close();
      _socket = null;
    }

    await _controller.close();
    _controller = StreamController<UVData>.broadcast();

    await _releaseMulticastLock();

    LoggerService.info('Multicast parado', tag: _tag);
  }

  /// Processa eventos do socket UDP
  static void _handleEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final datagram = _socket?.receive();
    if (datagram == null) return;

    try {
      final payload = utf8.decode(datagram.data);
      final json = jsonDecode(payload) as Map<String, dynamic>;
      final data = UVData.fromJson(json);

      _latestData = data;
      _lastReceived = DateTime.now();
      _controller.add(data);
    } catch (e) {
      final msg = e.toString();
      LoggerService.warning(
        'Pacote multicast inválido: ${msg.length > 80 ? msg.substring(0, 80) : msg}',
        tag: _tag,
      );
    }
  }

  /// Adquire o Android MulticastLock via platform channel
  static Future<void> _acquireMulticastLock() async {
    if (_lockAcquired) return;
    try {
      await _channel.invokeMethod('acquireMulticastLock');
      _lockAcquired = true;
      LoggerService.info('MulticastLock adquirido', tag: _tag);
    } on MissingPluginException {
      // Plataforma não suporta (iOS, web, desktop, testes) — ignora
      LoggerService.info('MulticastLock não disponível nesta plataforma',
          tag: _tag);
    } catch (e) {
      LoggerService.warning('Falha ao adquirir MulticastLock',
          tag: _tag, error: e);
    }
  }

  /// Libera o Android MulticastLock
  static Future<void> _releaseMulticastLock() async {
    if (!_lockAcquired) return;
    try {
      await _channel.invokeMethod('releaseMulticastLock');
      _lockAcquired = false;
      LoggerService.info('MulticastLock liberado', tag: _tag);
    } on MissingPluginException {
      _lockAcquired = false;
    } catch (e) {
      LoggerService.warning('Falha ao liberar MulticastLock',
          tag: _tag, error: e);
    }
  }

  /// Limpa o estado (para testes)
  static void reset() {
    _latestData = null;
    _lastReceived = null;
  }
}
