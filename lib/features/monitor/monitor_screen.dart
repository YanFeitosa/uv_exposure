import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/exposure_provider.dart';
import '../../core/services/foreground_service.dart';
import '../../shared/widgets/info_box.dart';
import '../../shared/widgets/connection_status_badge.dart';

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen>
    with WidgetsBindingObserver {
  bool _gapDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ExposureProvider>();
      if (!provider.isMonitoring) {
        final started = await provider.startMonitoring();
        if (!started && mounted) {
          _showConnectionFailedDialog();
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = context.read<ExposureProvider>();

    if (state == AppLifecycleState.paused) {
    } else if (state == AppLifecycleState.resumed) {
      // Reconecta ao sensor ao retomar
      if (provider.isMonitoring) {
        provider.retryConnection();
      }
    }
  }

  void _showConnectionFailedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Sensor não encontrado'),
        content: const Text(
          'Não foi possível estabelecer conexão com o dispositivo. '
          'Verifique se o SunSense está ligado e na mesma rede.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<ExposureProvider>().startMonitoring(force: true);
            },
            child: const Text('Continuar mesmo assim'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final provider = context.read<ExposureProvider>();
              final started = await provider.startMonitoring();
              if (!started && mounted) {
                _showConnectionFailedDialog();
              }
            },
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final provider = context.read<ExposureProvider>();

    if (!provider.isMonitoring) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(AppStrings.confirm),
          content: const Text(AppStrings.confirmBackMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () async {
                await provider.stopMonitoring();
                if (context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text(AppStrings.confirm),
            ),
          ],
        );
      },
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(AppStrings.appTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _onWillPop()) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: ConnectionStatusBadge(),
            ),
          ],
        ),
        body: Consumer<ExposureProvider>(
          builder: (context, provider, child) {
            // Exibe diálogo de gap
            if (provider.gapDetected &&
                !provider.gapDismissed &&
                !_gapDialogShown) {
              _gapDialogShown = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _showGapDialog(provider);
              });
            }
            // Reseta flag para permitir futuro gap
            if (provider.gapDismissed) {
              _gapDialogShown = false;
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final screenHeight = constraints.maxHeight;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: screenHeight * 0.02),

                        // Banner Modo Demo
                        if (provider.isDemoMode)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.warningBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.warning, width: 2),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.science,
                                    color: AppColors.warning, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  AppStrings.demoBannerText,
                                  style: TextStyle(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Banner de cache
                        if (provider.connectionStatus ==
                            ConnectionStatus.usingCache)
                          _buildCacheWarningBanner(provider),

                        if (provider.connectionError != null &&
                            provider.connectionStatus ==
                                ConnectionStatus.disconnected)
                          _buildConnectionErrorBanner(provider),

                        // Alerta de monitoramento parado
                        if (provider.stoppedDueToDisconnection)
                          _buildStoppedAlert(provider),

                        // Caixas de informação
                        InfoBox(
                          title: AppStrings.elapsedTime,
                          info: provider.formatTime(provider.secondsElapsed),
                          infoColor: AppColors.getExposureColor(
                            provider.accumulatedExposurePercent,
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.02),

                        InfoBox(
                          title: AppStrings.safeExposureTime,
                          info: provider.displayRemainingTime,
                          infoColor: AppColors.getExposureColor(
                            provider.accumulatedExposurePercent,
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.02),

                        InfoBox(
                          title: AppStrings.accumulatedExposure,
                          info:
                              '${provider.accumulatedExposurePercent.toStringAsFixed(2)} %',
                          infoColor: AppColors.getExposureColor(
                            provider.accumulatedExposurePercent,
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.02),

                        InfoBox(
                          title: AppStrings.globalUVIndex,
                          info: provider.currentUVIndex.toStringAsFixed(0),
                          infoColor: AppColors.getUVIndexColor(
                              provider.currentUVIndex),
                          subtitle:
                              _getUVIndexDescription(provider.currentUVIndex),
                        ),

                        SizedBox(height: screenHeight * 0.02),

                        // Botão parar alarme
                        if (provider.alarmActive)
                          ElevatedButton.icon(
                            onPressed: () => provider.stopAlarm(),
                            icon: const Icon(Icons.volume_off),
                            label: const Text(AppStrings.stopAlarm),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: AppColors.textOnSecondary,
                            ),
                          ),

                        SizedBox(height: screenHeight * 0.02),

                        // Botão finalizar monitoramento
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              if (await _onWillPop()) {
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              }
                            },
                            icon: const Icon(Icons.stop),
                            label: const Text(AppStrings.endMonitoring),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.015,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.02),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildConnectionErrorBanner(ExposureProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.warning,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.connectionError ?? AppStrings.deviceNotFound,
              style: const TextStyle(
                color: AppColors.warningTextStrong,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: AppColors.warning,
            ),
            onPressed: provider.retryConnection,
            tooltip: AppStrings.retryConnection,
          ),
        ],
      ),
    );
  }

  String _getUVIndexDescription(double uvIndex) {
    if (uvIndex <= 2) return AppStrings.uvLow;
    if (uvIndex <= 5) return AppStrings.uvModerate;
    if (uvIndex <= 7) return AppStrings.uvHigh;
    if (uvIndex <= 10) return AppStrings.uvVeryHigh;
    return AppStrings.uvExtreme;
  }

  /// Banner de aviso quando usando dados do cache
  Widget _buildCacheWarningBanner(ExposureProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.wifi_off, color: AppColors.warning, size: 28),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.connectionLostUsingCache,
                      style: TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.warning),
                onPressed: provider.retryConnection,
                tooltip: AppStrings.retryConnection,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Diálogo de compensação de gap (suspensão do sistema)
  void _showGapDialog(ExposureProvider provider) {
    final minutes = provider.lastGapDurationSeconds ~/ 60;
    final seconds = provider.lastGapDurationSeconds % 60;
    final durationText =
        minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';

    final compMinutes = provider.lastGapCompensatedSeconds ~/ 60;
    final compSeconds = provider.lastGapCompensatedSeconds % 60;
    final compText =
        compMinutes > 0 ? '${compMinutes}m ${compSeconds}s' : '${compSeconds}s';

    final body = provider.gapExceededMax
        ? AppStrings.gapDialogBodyExceeded
            .replaceAll('{duration}', durationText)
            .replaceAll('{compensated}', compText)
            .replaceAll(
                '{maxMinutes}', '${AppConstants.maxGapSimulationSeconds ~/ 60}')
            .replaceAll('{uvIndex}', provider.gapUVIndex.toStringAsFixed(1))
        : AppStrings.gapDialogBody
            .replaceAll('{duration}', durationText)
            .replaceAll('{compensated}', compText)
            .replaceAll('{uvIndex}', provider.gapUVIndex.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          icon: Icon(
            provider.gapExceededMax ? Icons.warning_amber : Icons.info_outline,
            color: provider.gapExceededMax ? AppColors.warning : AppColors.info,
            size: 36,
          ),
          title: const Text(AppStrings.gapDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(body),
              if (Platform.isAndroid) ...[
                const SizedBox(height: 16),
                const Text(
                  AppStrings.gapDialogBatteryHint,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSubtle,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (Platform.isAndroid)
              TextButton.icon(
                onPressed: () {
                  ForegroundService.openBatteryOptimizationSettings();
                },
                icon: const Icon(Icons.battery_saver, size: 18),
                label: const Text(AppStrings.gapOpenBatterySettings),
              ),
            TextButton(
              onPressed: () {
                provider.dismissGapWarning();
                Navigator.of(ctx).pop();
              },
              child: const Text(AppStrings.gapDismiss),
            ),
          ],
        );
      },
    );
  }

  /// Alerta de monitoramento parado por desconexão
  Widget _buildStoppedAlert(ExposureProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error, width: 2),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 32),
              SizedBox(width: 8),
              Text(
                AppStrings.monitoringPaused,
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.noConnectionRetryMessage.replaceAll(
                '{minutes}', '${AppConstants.cacheExpiration.inMinutes}'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.errorDark,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              final reconnected = await provider.retryConnection();
              if (!context.mounted) return;
              if (reconnected) {
                provider.startMonitoring(force: true);
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text(AppStrings.retryReconnect),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
