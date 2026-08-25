import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/records_provider.dart';
import '../theme/app_theme.dart';

class KilogramsBarChart extends StatelessWidget {
  const KilogramsBarChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RecordsProvider>(
      builder: (context, provider, child) {
        final kilogramsData = provider.kilogramsByFarm;

        if (kilogramsData.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppPalette.cardBorder),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  size: 44,
                  color: AppPalette.textMuted.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Sin datos de producción',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Registra ventas para ver la comparativa por finca.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppPalette.textMuted),
                ),
              ],
            ),
          );
        }

        final barGroups = <BarChartGroupData>[];
        final farmNames = kilogramsData.keys.toList();

        for (int i = 0; i < farmNames.length; i++) {
          final kg = kilogramsData[farmNames[i]]!;
          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: kg,
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppPalette.espresso, AppPalette.caramel],
                  ),
                  width: 22,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: _getMaxY(kilogramsData),
                    color: AppPalette.crema,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppPalette.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        color: AppPalette.cocoa,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Producción por Finca',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppPalette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.caramel.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Kg Totales',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.caramelDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxY(kilogramsData),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppPalette.espresso,
                        tooltipRoundedRadius: 10,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final farmName = farmNames[group.x.toInt()];
                          return BarTooltipItem(
                            '$farmName\n',
                            const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: '${rod.toY.toStringAsFixed(1)} kg',
                                style: const TextStyle(
                                  color: AppPalette.caramel,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    barGroups: barGroups,
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < farmNames.length) {
                              final name = farmNames[index];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  name.length > 7
                                      ? '${name.substring(0, 7)}..'
                                      : name,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppPalette.textSecondary,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                          reservedSize: 28,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 38,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const Text('');
                            return Text(
                              '${value.toInt()}k',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppPalette.textMuted,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: AppPalette.cardBorder.withValues(alpha: 0.6),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _getMaxY(Map<String, double> data) {
    if (data.isEmpty) return 100;
    final maxValue = data.values.reduce((a, b) => a > b ? a : b);
    return (maxValue * 1.25).clamp(20, double.infinity);
  }
}
