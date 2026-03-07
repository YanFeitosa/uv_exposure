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
  String? _skinType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final demoMode = await StorageService.getDemoMode();
    final soundAlarm = await StorageService.isSoundAlarmEnabled();
    final skinType = await StorageService.getSkinType();

    if (mounted) {
      setState(() {
        _demoMode = demoMode;
        _soundAlarm = soundAlarm;
        _skinType = skinType;
        _isLoading = false;
      });
    }
  }

  /// Retorna a lista de fototipos filtrada pelo modo Demo
  List<String> get _filteredSkinTypes {
    if (_demoMode) return AppStrings.skinTypes;
    return AppStrings.skinTypes.where((s) => !s.contains('Demo')).toList();
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
                // Fototipo de Pele
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    AppStrings.skinTypeLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person),
                    ),
                    value: _filteredSkinTypes.contains(_skinType)
                        ? _skinType
                        : null,
                    items: _filteredSkinTypes.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _skinType = newValue;
                      });
                      if (newValue != null) {
                        StorageService.saveSkinType(newValue);
                      }
                    },
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(),

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
                      // Reseta fototipo Demo se desativou
                      if (!_demoMode &&
                          _skinType != null &&
                          _skinType!.contains('Demo')) {
                        _skinType = null;
                        StorageService.saveSkinType('');
                      }
                    });
                    StorageService.setDemoMode(value);
                  },
                ),
              ],
            ),
    );
  }
}
