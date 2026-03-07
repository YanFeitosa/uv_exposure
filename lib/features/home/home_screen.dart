import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/exposure_provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/storage_service.dart';
import '../monitor/monitor_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestNotificationPermission();
      _checkSkinType();
      _checkPendingSession();
    });
  }

  // Verifica se o fototipo de pele já foi definido
  Future<void> _checkSkinType() async {
    final skinType = await StorageService.getSkinType();
    if (skinType == null || skinType.isEmpty) {
      if (!mounted) return;
      await _showSkinTypePopup();
    }
  }

  // Popup para selecionar fototipo na primeira abertura
  Future<void> _showSkinTypePopup() async {
    String? selectedSkinType;
    final demoMode = await StorageService.getDemoMode();
    final skinTypes = demoMode
        ? AppStrings.skinTypes
        : AppStrings.skinTypes.where((s) => !s.contains('Demo')).toList();

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              icon: Icon(Icons.person, color: AppColors.secondary, size: 36),
              title: const Text(AppStrings.skinTypePopupTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(AppStrings.skinTypePopupBody),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: AppStrings.skinTypeLabel,
                      prefixIcon: Icon(Icons.person),
                    ),
                    value: selectedSkinType,
                    items: skinTypes.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setDialogState(() {
                        selectedSkinType = newValue;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: selectedSkinType != null
                      ? () {
                          StorageService.saveSkinType(selectedSkinType!);
                          Navigator.of(ctx).pop();
                        }
                      : null,
                  child: const Text(AppStrings.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Verifica sessão pendente para restauração
  Future<void> _checkPendingSession() async {
    final lastSession = await StorageService.getLastSession();
    if (lastSession == null) return;
    if (!mounted) return;

    final spf = lastSession['spf'] as double;
    final skinType = lastSession['skinType'] as String;
    final accumulated = lastSession['accumulatedExposure'] as double;
    final seconds = lastSession['secondsElapsed'] as int;
    final timestamp = lastSession['timestamp'] as String?;

    String timeInfo = '';
    if (timestamp != null) {
      try {
        final dt = DateTime.parse(timestamp);
        timeInfo =
            '\nSalva em: ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    final mins = seconds ~/ 60;
    final secs = seconds % 60;

    final spfLabel = spf <= 0
        ? AppStrings.noSunscreen
        : '${AppStrings.spfPrefix} ${spf.toInt()}';

    final shouldRestore = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.restore, color: Colors.orange, size: 36),
        title: const Text('Sessão Anterior Encontrada'),
        content: Text(
          'Existe uma sessão interrompida:\n\n'
          '• Fototipo: $skinType\n'
          '• $spfLabel\n'
          '• Exposição: ${accumulated.toStringAsFixed(1)}%\n'
          '• Tempo: ${mins}m ${secs}s'
          '$timeInfo\n\n'
          'Deseja restaurar e continuar o monitoramento?',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await StorageService.clearLastSession();
              if (ctx.mounted) Navigator.of(ctx).pop(false);
            },
            child: const Text('Descartar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (shouldRestore == true && mounted) {
      final provider = context.read<ExposureProvider>();
      provider.setDemoMode(skinType.contains('Demo'));
      provider.initialize(spf: spf, skinType: skinType);
      final restored = await provider.restoreLastSession();
      if (restored && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MonitorScreen()),
        );
      }
    }
  }

  // Permissão de notificação
  Future<void> _requestNotificationPermission() async {
    if (kIsWeb) return;

    final hasPermission = await NotificationService.areNotificationsEnabled();
    if (hasPermission) return;

    final alreadyAsked =
        await StorageService.wasNotificationPermissionAsked();
    if (alreadyAsked) return;

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.orange),
            SizedBox(width: 8),
            Text(AppStrings.notificationsDialogTitle),
          ],
        ),
        content: const Text(AppStrings.notificationsDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.later),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.allow),
          ),
        ],
      ),
    );

    await StorageService.setNotificationPermissionAsked();
    if (shouldRequest == true) {
      await NotificationService.requestPermission();
    }
  }

  // Popup para selecionar SPF antes de iniciar monitoramento
  Future<void> _showStartMonitoringPopup() async {
    String? selectedSpf;
    final skinType = await StorageService.getSkinType();
    final demoMode = await StorageService.getDemoMode();

    if (skinType == null || skinType.isEmpty) {
      await _showSkinTypePopup();
      return;
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              icon: Icon(Icons.wb_sunny, color: AppColors.primary, size: 36),
              title: const Text(AppStrings.startMonitoringTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(AppStrings.selectSpfMessage),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: AppStrings.spfLabel,
                      prefixIcon: Icon(Icons.shield),
                    ),
                    value: selectedSpf,
                    items: AppStrings.spfValues.map((String value) {
                      final label = value == '0'
                          ? AppStrings.noSunscreen
                          : '${AppStrings.spfPrefix} $value';
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setDialogState(() {
                        selectedSpf = newValue;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(AppStrings.cancel),
                ),
                ElevatedButton(
                  onPressed: selectedSpf != null
                      ? () {
                          Navigator.of(ctx).pop();
                          _startMonitoring(
                            spf: double.parse(selectedSpf!),
                            skinType: skinType,
                            demoMode: demoMode,
                          );
                        }
                      : null,
                  child: const Text(AppStrings.start),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _startMonitoring({
    required double spf,
    required String skinType,
    required bool demoMode,
  }) {
    final provider = context.read<ExposureProvider>();
    provider.setDemoMode(demoMode);
    provider.initialize(spf: spf, skinType: skinType);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MonitorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            tooltip: AppStrings.settings,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/history');
            },
            tooltip: AppStrings.exposureHistory,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.05),

                  // Logo SunSense
                  SizedBox(
                    height: screenHeight * 0.35,
                    child: Image.asset(
                      AppConstants.imageAssetPath,
                      width: screenWidth * 0.80,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.wb_sunny,
                          size: screenWidth * 0.4,
                          color: AppColors.primary,
                        );
                      },
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.06),

                  // Botão Iniciar Monitoramento
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showStartMonitoringPopup,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text(AppStrings.startMonitoring),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Informação de conexão WiFi
                  Card(
                    color: AppColors.primary.withOpacity(0.2),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppStrings.wifiInfoMessage,
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
