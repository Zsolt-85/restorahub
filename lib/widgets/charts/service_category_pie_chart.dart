import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:restorahub/models/appointment.dart';

class ServiceCategoryPieChart extends StatelessWidget {
  final List<Appointment> appointments;

  const ServiceCategoryPieChart({
    super.key,
    required this.appointments,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final categoryMap = <String, int>{};
    for (final appt in appointments) {
      final category = _extractCategory(appt.service);
      categoryMap[category] = (categoryMap[category] ?? 0) + 1;
    }

    final total = appointments.length;
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];

    final sections = categoryMap.entries.map((entry) {
      final color = colors[categoryMap.keys.toList().indexOf(entry.key) % colors.length];
      return PieChartSectionData(
        value: entry.value.toDouble(),
        color: color,
        radius: 40,
      );
    }).toList();

    final legendItems = categoryMap.entries.map((entry) {
      final color = colors[categoryMap.keys.toList().indexOf(entry.key) % colors.length];
      final percentage = total > 0 ? ((entry.value / total) * 100).toStringAsFixed(1) : '0.0';
      return _LegendItem(color: color, label: entry.key, count: entry.value, percentage: percentage);
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 32,
              sections: sections,
              pieTouchData: PieTouchData(
                enabled: true,
                touchCallback: (event, response) {
                  if (response != null && response.touchedSection != null) {}
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: legendItems,
          ),
        ),
      ],
    );
  }

  String _extractCategory(String service) {
    final parts = service.split(' — ');
    return parts.first.trim();
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final String percentage;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 160,
          child: Text(
            '$label ($count · $percentage%)',
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
