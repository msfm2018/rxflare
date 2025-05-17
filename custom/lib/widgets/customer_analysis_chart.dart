import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CustomerAnalysisChart extends StatelessWidget {
  final List<FlSpot> itemData = [FlSpot(0, 1), FlSpot(1, 3), FlSpot(2, 7), FlSpot(3, 4), FlSpot(4, 9), FlSpot(5, 2), FlSpot(6, 0)];

  final List<FlSpot> userData = [FlSpot(0, 1), FlSpot(1, 2), FlSpot(2, 3), FlSpot(3, 1), FlSpot(4, 2), FlSpot(5, 2), FlSpot(6, 1)];

  CustomerAnalysisChart({super.key});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: itemData,
            isCurved: true,
            //  Color: Colors.red,
            barWidth: 3,
            dotData: FlDotData(show: false),
          ),
          LineChartBarData(
            spots: userData,
            isCurved: true,
            //  Color: Colors.blue,
            barWidth: 3,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
