import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/city.dart';
import '../models/forecast.dart';
import '../utils/formatters.dart';
import '../widgets/message_view.dart';

/// Gráfico de linhas com as temperaturas mínima e máxima de cada dia.
class ChartScreen extends StatelessWidget {
  final City city;
  final Forecast forecast;
  const ChartScreen({super.key, required this.city, required this.forecast});

  static const _minColor = Colors.blue;
  static const _maxColor = Colors.deepOrange;

  @override
  Widget build(BuildContext context) {
    final days = forecast.days;
    final minSpots = <FlSpot>[];
    final maxSpots = <FlSpot>[];
    for (var i = 0; i < days.length; i++) {
      final d = days[i];
      if (d.min != null) minSpots.add(FlSpot(i.toDouble(), d.min!.toDouble()));
      if (d.max != null) maxSpots.add(FlSpot(i.toDouble(), d.max!.toDouble()));
    }
    final values = [...minSpots, ...maxSpots].map((s) => s.y).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Temperaturas • ${city.name}')),
      body: values.isEmpty
          ? const MessageView(
              icon: Icons.show_chart,
              message: 'Não há dados de temperatura para exibir no gráfico.',
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 24, 24, 8),
                  child: SizedBox(
                    height: 320,
                    child: LineChart(_chartData(days, minSpots, maxSpots, values)),
                  ),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Legend(color: _minColor, label: 'Mínima (°C)'),
                    SizedBox(width: 24),
                    _Legend(color: _maxColor, label: 'Máxima (°C)'),
                  ],
                ),
                const Spacer(),
                const SourceFooter(),
              ],
            ),
    );
  }

  LineChartData _chartData(
      List<DayForecast> days, List<FlSpot> minSpots, List<FlSpot> maxSpots, List<double> values) {
    final minY = (values.reduce(math.min) - 3).floorToDouble();
    final maxY = (values.reduce(math.max) + 3).ceilToDouble();

    LineChartBarData line(List<FlSpot> spots, Color color) => LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 3,
          dotData: const FlDotData(show: true),
        );

    return LineChartData(
      minX: 0,
      maxX: math.max(1, days.length - 1).toDouble(),
      minY: minY,
      maxY: maxY,
      gridData: const FlGridData(show: true),
      borderData: FlBorderData(show: true),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (v, _) => Text('${v.toInt()}°', style: const TextStyle(fontSize: 11)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 32,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (v != i.toDouble() || i < 0 || i >= days.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(formatShortDate(days[i].date), style: const TextStyle(fontSize: 11)),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touched) => touched
              .map((s) => LineTooltipItem(
                    '${s.y.toInt()}°C',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ))
              .toList(),
        ),
      ),
      lineBarsData: [
        if (minSpots.isNotEmpty) line(minSpots, _minColor),
        if (maxSpots.isNotEmpty) line(maxSpots, _maxColor),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 14, height: 14, color: color),
        const SizedBox(width: 6),
        Text(label),
      ]);
}
