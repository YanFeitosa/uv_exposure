import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.aboutTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo
            const Icon(
              Icons.wb_sunny,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${AppStrings.aboutVersion} 3.0.2',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textHint,
                  ),
            ),
            const SizedBox(height: 24),

            // Descrição
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.textOnCard),
                        const SizedBox(width: 8),
                        Text(
                          'Descrição',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textOnCard,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(AppStrings.aboutDescription,
                        style: TextStyle(color: AppColors.textOnCardMuted)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Disclaimer
            Card(
              color: AppColors.warningBackgroundSubtle,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber,
                            color: AppColors.warningText),
                        const SizedBox(width: 8),
                        Text(
                          'Aviso Importante',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warningText,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      AppStrings.aboutDisclaimer,
                      style: TextStyle(color: AppColors.warningTextDark),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tecnologias
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.build, color: AppColors.textOnCard),
                        const SizedBox(width: 8),
                        Text(
                          'Tecnologias',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textOnCard,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(AppStrings.aboutTechnology,
                        style: TextStyle(color: AppColors.textOnCardMuted)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
