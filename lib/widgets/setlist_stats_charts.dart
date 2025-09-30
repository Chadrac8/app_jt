import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../theme.dart';

class SetlistStatsPieChart extends StatelessWidget {
  final Map<String, int> data;
  final String title;
  final List<Color> colors;

  const SetlistStatsPieChart({
    super.key,
    required this.data,
    required this.title,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold<int>(0, (a, b) => a + b);
    final sections = <PieChartSectionData>[];
    int i = 0;
    data.forEach((label, value) {
      final percent = total > 0 ? (value / total * 100).toStringAsFixed(1) : '0';
      sections.add(PieChartSectionData(
        color: colors[i % colors.length],
        value: value.toDouble(),
        title: '$label\n$percent%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: AppTheme.fontBold, color: AppTheme.white100),
      ));
      i++;
    });
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
