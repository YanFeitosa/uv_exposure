import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/exposure_provider.dart';
import '../../shared/widgets/info_box.dart';
import '../../shared/widgets/connection_status_badge.dart';

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Inicia o monitoramento
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExposureProvider>().startMonitoring();
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
      // App em background - continua monitorando
    } else if (state == AppLifecycleState.resumed) {
      // App retomado
      if (provider.isMonitoring) {
        provider.retryConnection();
      }
    }
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
                        
                        // Connection Error Banner
                        if (provider.connectionStatus == ConnectionStatus.usingCache)
                          _buildCacheWarningBanner(provider),
                        
                        if (provider.connectionError != null && 
                            provider.connectionStatus == ConnectionStatus.disconnected)
                          _buildConnectionErrorBanner(provider),
                        
                        // Stopped due to disconnection alert
                        if (provider.stoppedDueToDisconnection)
                          _buildStoppedAlert(provider),
                        
                        // Info Boxes
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
                          info: provider.formatTime(provider.remainingSafeExposureTime),
                          infoColor: AppColors.getExposureColor(
                            provider.accumulatedExposurePercent,
                          ),
                        ),
                        
                        SizedBox(height: screenHeight * 0.02),
                        
                        InfoBox(
                          title: AppStrings.accumulatedExposure,
                          info: '${provider.accumulatedExposurePercent.toStringAsFixed(2)} %',
                          infoColor: AppColors.getExposureColor(
                            provider.accumulatedExposurePercent,
                          ),
                        ),
                        
                        SizedBox(height: screenHeight * 0.02),
                        
                        InfoBox(
                          title: AppStrings.globalUVIndex,
                          info: provider.currentUVIndex.toStringAsFixed(0),
                          infoColor: AppColors.getUVIndexColor(provider.currentUVIndex),
                          subtitle: _getUVIndexDescription(provider.currentUVIndex),
                        ),
                        
                        SizedBox(height: screenHeight * 0.02),
                        
                        // Alarm control button
                        if (provider.alarmPlayed)
                          ElevatedButton.icon(
                            onPressed: () => provider.stopAlarm(),
                            icon: const Icon(Icons.volume_off),
                            label: const Text('Stop Alarm'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
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
        color: provider.connectionStatus == ConnectionStatus.usingCache
            ? Colors.blue.shade100
            : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: provider.connectionStatus == ConnectionStatus.usingCache
              ? Colors.blue
              : Colors.orange,
        ),
      ),
      child: Row(
        children: [
          Icon(
            provider.connectionStatus == ConnectionStatus.usingCache
                ? Icons.cloud_off
                : Icons.warning_amber,
            color: provider.connectionStatus == ConnectionStatus.usingCache
                ? Colors.blue
                : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.connectionStatus == ConnectionStatus.usingCache
                  ? 'Using cached data. Device not reachable.'
                  : provider.connectionError!,
              style: TextStyle(
                color: provider.connectionStatus == ConnectionStatus.usingCache
                    ? Colors.blue.shade800
                    : Colors.orange.shade800,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: provider.connectionStatus == ConnectionStatus.usingCache
                  ? Colors.blue
                  : Colors.orange,
            ),
            onPressed: provider.retryConnection,
            tooltip: AppStrings.retryConnection,
          ),
        ],
      ),
    );
  }

  String _getUVIndexDescription(double uvIndex) {
    if (uvIndex <= 2) return 'Low';
    if (uvIndex <= 5) return 'Moderate';
    if (uvIndex <= 7) return 'High';
    if (uvIndex <= 10) return 'Very High';
    return 'Extreme';
  }

  /// Banner de aviso quando usando dados em cache
  Widget _buildCacheWarningBanner(ExposureProvider provider) {
    final remainingMinutes = provider.cacheTimeRemaining ~/ 60;
    final remainingSeconds = provider.cacheTimeRemaining % 60;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.wifi_off, color: Colors.orange, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Conexão perdida - Usando cache',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'O monitoramento será pausado em ${remainingMinutes}m ${remainingSeconds}s',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.orange),
                onPressed: provider.retryConnection,
                tooltip: AppStrings.retryConnection,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: provider.cacheTimeRemaining / 300, // 5 minutos = 300s
              backgroundColor: Colors.orange.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  /// Alerta quando o monitoramento foi parado por falta de conexão
  Widget _buildStoppedAlert(ExposureProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 32),
              SizedBox(width: 8),
              Text(
                'Monitoramento Pausado',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Sem conexão com o dispositivo por mais de 5 minutos.\n'
            'Reconecte-se à rede WiFi do SunSense e tente novamente.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red.shade800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              provider.retryConnection();
              if (provider.connectionStatus == ConnectionStatus.connected) {
                provider.startMonitoring();
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar Reconectar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
