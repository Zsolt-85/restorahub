import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:restorahub/helpers/format_helper.dart';
import 'package:restorahub/models/payment.dart';

class RevenueTrendChart extends StatelessWidget {
  final List<Payment> payments;
  final DateTime start;
  final DateTime end;
  final String currency;

  const RevenueTrendChart({
    super.key,
    required this.payments,
    required this.start,
    required this.end,
    this.currency = 'EUR',
  });

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return const Center(child: Text('No revenue data'));
    }

    final dayMap = <DateTime, double>{};
    for (final p in payments) {
      if (p.status == PaymentStatus.completed) {
        final day = DateTime(p.appointmentDate.year, p.appointmentDate.month, p.appointmentDate.day);
        dayMap[day] = (dayMap[day] ?? 0) + p.amount;
      }
    }

    final days = <DateTime>[];
    for (var d = DateTime(start.year, start.month, start.day); d.isBefore(DateTime(end.year, end.month, end.day)); d = d.add(const Duration(days: 1))) {
      days.add(d);
    }

    if (days.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final spots = days.map((day) {
      final key = DateTime(day.year, day.month, day.day);
      final revenue = dayMap[key] ?? 0;
      return FlSpot(days.indexOf(day).toDouble(), revenue);
    }).toList();

    final labels = days.map((day) => '${day.month}/${day.day}').toList();

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final interval = maxY > 0 ? (maxY / 5).ceil().toDouble() : 1.0;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (days.length / 5).ceil().toDouble(),
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return Padding(padding: const EdgeInsets.only(top: 8), child: Text(labels[index], style: const TextStyle(fontSize: 10)));
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval > 0 ? interval : 1.0,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.blueGrey.withValues(alpha: 0.8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index >= 0 && index < days.length) {
                  final date = days[index];
                  final key = DateTime(date.year, date.month, date.day);
                  final revenue = dayMap[key] ?? 0;
                  return LineTooltipItem(
                    '${date.month}/${date.day}/${date.year}\n${FormatHelper.formatCurrency(revenue, currency: currency)}',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }
                return const LineTooltipItem('', TextStyle(color: Colors.white));
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: Theme.of(context).primaryColor,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withValues(alpha: 0.4),
                  Theme.of(context).primaryColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}