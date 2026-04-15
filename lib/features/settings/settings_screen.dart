import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _demoMode = false;
  bool _soundAlarm = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final demoMode = await StorageService.getDemoMode();
    final soundAlarm = await StorageService.isSoundAlarmEnabled();

    if (mounted) {
      setState(() {
        _demoMode = demoMode;
        _soundAlarm = soundAlarm;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Alarme Sonoro
                SwitchListTile(
                  title: const Text(AppStrings.soundAlarmLabel),
                  subtitle: const Text(AppStrings.soundAlarmDescription),
                  value: _soundAlarm,
                  secondary: Icon(
                    _soundAlarm ? Icons.volume_up : Icons.volume_off,
                    color: AppColors.secondary,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _soundAlarm = value;
                    });
                    StorageService.setSoundAlarmEnabled(value);
                  },
                ),

                const Divider(),

                // Modo Demo
                SwitchListTile(
                  title: const Text(AppStrings.demoModeLabel),
                  subtitle: const Text(AppStrings.demoBannerText),
                  value: _demoMode,
                  secondary: Icon(
                    Icons.science,
                    color: _demoMode ? Colors.orange : AppColors.secondary,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _demoMode = value;
                    });
                    StorageService.setDemoMode(value);
                  },
                ),
              ],
            ),
    );
  }
}
