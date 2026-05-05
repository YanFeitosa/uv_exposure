import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/exposure_model.dart';
import '../../core/providers/history_provider.dart';
import '../../core/services/export_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedPeriod = 7; // dias

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<HistoryProvider>().loadSessionsLastDays(_selectedPeriod);
  }

  Future<void> _exportData(String format) async {
    final sessions = context.read<HistoryProvider>().sessions;
    if (sessions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.exportNoData)),
      );
      return;
    }

    try {
      final result = await ExportService.exportAndShare(
        sessions,
        format: format,
        subject: AppStrings.exportShareSubject,
        text: AppStrings.exportShareText,
      );

      if (!mounted) return;

      final String message;
      if (result.wasShared) {
        message = AppStrings.exportShared;
      } else if (result.wasDismissed) {
        message = '${AppStrings.exportShareDismissed}\n${result.path}';
      } else {
        // Plataformas sem suporte a share (desktop, testes) caem aqui.
        message =
            '${AppStrings.exportSuccess}\n${AppStrings.exportFileSaved} ${result.path}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.exportError}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.exposureHistory),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download),
            tooltip: AppStrings.exportData,
            onSelected: (format) => _exportData(format),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, size: 20),
                    SizedBox(width: 8),
                    Text(AppStrings.exportCSV),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'json',
                child: Row(
                  children: [
                    Icon(Icons.data_object, size: 20),
                    SizedBox(width: 8),
                    Text(AppStrings.exportJSON),
                  ],
                ),
              ),
            ],
          ),
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_list),
            onSelected: (days) {
              setState(() {
                _selectedPeriod = days;
              });
              _loadData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 1, child: Text(AppStrings.today)),
              const PopupMenuItem(value: 7, child: Text(AppStrings.last7Days)),
            ],
          ),
        ],
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: AppColors.errorMuted),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text(AppStrings.tryAgain),
                  ),
                ],
              ),
            );
          }

          if (!provider.hasData) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history,
                      size: 64, color: AppColors.emptyStateIcon),
                  SizedBox(height: 16),
                  Text(
                    AppStrings.noHistoryData,
                    style: TextStyle(color: AppColors.emptyStateText),
                  ),
                ],
              ),
            );
          }

          final stats = provider.getStatistics();
          final chartData = provider.getDailyExposureData(_selectedPeriod);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cards de estatísticas
                _buildStatisticsSection(stats),

                const SizedBox(height: 24),

                // Gráfico de barras
                _buildChartSection(chartData),

                const SizedBox(height: 24),

                // Lista de sessões
                _buildSessionList(provider.sessions),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsSection(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.statistics,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                AppStrings.sessions,
                '${stats['totalSessions'] ?? 0}',
                Icons.timer,
                AppColors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                AppStrings.averageExposure,
                '${((stats['averageExposure'] ?? 0.0) as double).toStringAsFixed(1)}%',
                Icons.wb_sunny,
                AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                AppStrings.maxUV,
                (stats['maxUVIndex'] as double).toStringAsFixed(1),
                Icons.trending_up,
                AppColors.exposureDanger,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                AppStrings.totalTime,
                _formatDuration(stats['totalDuration'] as Duration),
                Icons.access_time,
                AppColors.info,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    // Cor de contraste para o card
    final displayColor =
        color == AppColors.secondary ? AppColors.textOnCard : color;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: displayColor, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: displayColor,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textOnCardMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.dailyExposure,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _getMaxExposure(data),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${rod.toY.toStringAsFixed(1)}%',
                      const TextStyle(color: AppColors.textOnCard),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < data.length) {
                        final date = data[index]['date'] as DateTime;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}%',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(
                show: true,
                horizontalInterval: 25,
                drawVerticalLine: false,
              ),
              barGroups: _createBarGroups(data),
            ),
          ),
        ),
      ],
    );
  }

  double _getMaxExposure(List<Map<String, dynamic>> data) {
    double max = 100;
    for (final item in data) {
      final exposure = item['exposure'] as double;
      if (exposure > max) max = exposure;
    }
    return max * 1.1;
  }

  List<BarChartGroupData> _createBarGroups(List<Map<String, dynamic>> data) {
    return List.generate(data.length, (index) {
      final exposure = data[index]['exposure'] as double;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: exposure,
            color: AppColors.getExposureColor(exposure),
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }

  Widget _buildSessionList(List<ExposureSession> sessions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.sessions,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return _buildSessionCard(session);
          },
        ),
      ],
    );
  }

  Widget _buildSessionCard(ExposureSession session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              AppColors.getExposureColor(session.maxExposurePercent),
          child: Text(
            '${session.maxExposurePercent.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: AppColors.textOnCard,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          _formatDateTime(session.startTime),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textOnCard,
          ),
        ),
        subtitle: Text(
          '${AppStrings.durationLabel}: ${_formatDuration(session.duration)} • ${AppStrings.maxUV} ${session.maxUVIndex.toStringAsFixed(1)}',
          style: const TextStyle(color: AppColors.textOnCardMuted),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${AppStrings.spfPrefix} ${session.spf.toInt()}',
              style: const TextStyle(
                color: AppColors.textOnCard,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              session.skinType,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textOnCardSubtle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (date == today) {
      dateStr = AppStrings.today;
    } else if (date == today.subtract(const Duration(days: 1))) {
      dateStr = AppStrings.yesterday;
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$dateStr ${AppStrings.atTime} $time';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
