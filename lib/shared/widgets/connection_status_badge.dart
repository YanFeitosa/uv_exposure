import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/exposure_provider.dart';

/// Badge compacto que exibe o status de conexão com o dispositivo IoT SunSense
class ConnectionStatusBadge extends StatelessWidget {
  const ConnectionStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExposureProvider>(
      builder: (context, provider, child) {
        final status = provider.connectionStatus;
        final isConnected = status == ConnectionStatus.connected;
        final isUsingCache = status == ConnectionStatus.usingCache;
        final isConnecting = status == ConnectionStatus.connecting;

        Color backgroundColor;
        Color borderColor;
        Color textColor;
        IconData icon;
        String text;

        if (isConnecting) {
          backgroundColor = AppColors.connecting.withValues(alpha: 0.12);
          borderColor = AppColors.connecting;
          textColor = AppColors.connecting;
          icon = Icons.wifi;
          text = AppStrings.connecting;
        } else if (isConnected) {
          backgroundColor = AppColors.connected.withValues(alpha: 0.12);
          borderColor = AppColors.connected;
          textColor = AppColors.connected;
          icon = Icons.wifi;
          text = AppStrings.connected;
        } else if (isUsingCache) {
          backgroundColor = AppColors.usingCache.withValues(alpha: 0.12);
          borderColor = AppColors.usingCache;
          textColor = AppColors.usingCache;
          icon = Icons.cloud_off;
          text = AppStrings.usingCache;
        } else {
          backgroundColor = AppColors.disconnected.withValues(alpha: 0.12);
          borderColor = AppColors.disconnected;
          textColor = AppColors.disconnected;
          icon = Icons.wifi_off;
          text = AppStrings.disconnected;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isConnecting)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              else
                Icon(icon, size: 14, color: textColor),
              const SizedBox(width: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
