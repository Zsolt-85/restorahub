import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:restorahub/models/appointment.dart';

class PeakHoursBarChart extends StatelessWidget {
  final List<Appointment> appointments;

  const PeakHoursBarChart({
    super.key,
    required this.appointments,
  });

  @override
  Widget build(BuildContext context) {
    final hourCounts = List<int>.filled(13, 0);
    for (final appt in appointments) {
      final hour = appt.dateTime.hour;
      if (hour >= 8 && hour <= 20) {
        hourCounts[hour - 8]++;
      }
    }

    final maxCount = hourCounts.reduce((a, b) => a > b ? a : b);
    if (maxCount == 0) {
      return const Center(child: Text('No data'));
    }

    final barGroups = hourCounts.asMap().entries.map((entry) {
      final count = entry.value;
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: count == maxCount && count > 0 ? Colors.redAccent : Theme.of(context).primaryColor,
            width: 14,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        final hour = value.toInt() + 8;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _formatHour(hour),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                barGroups: barGroups,
                maxY: (maxCount + 1).toDouble(),
              ),
            ),
          ),
        ),
        if (maxCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Peak: ${hourCounts.indexOf(maxCount) + 8}:00 ($maxCount bookings)',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
}
