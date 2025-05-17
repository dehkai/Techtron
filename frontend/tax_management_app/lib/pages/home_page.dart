import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff2C3930),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color:  Color(0xffF2F1F3),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Monthly Expenses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 500,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                              return Text(months[value.toInt() % months.length]);
                            },
                            reservedSize: 32,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 120, color: Colors.blue)]),
                        BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 200, color: Colors.blue)]),
                        BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 150, color: Colors.blue)]),
                        BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 300, color: Colors.blue)]),
                        BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 180, color: Colors.blue)]),
                        BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 90, color: Colors.blue)]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Expense Categories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(value: 40, color: Colors.blue, title: 'Food', radius: 50, titleStyle: TextStyle(color: Colors.white)),
                        PieChartSectionData(
                          value: 30,
                          color: Colors.orange,
                          title: 'Transport',
                          radius: 50,
                          titleStyle: TextStyle(color: Colors.white),
                        ),
                        PieChartSectionData(value: 15, color: Colors.green, title: 'Shopping', radius: 50, titleStyle: TextStyle(color: Colors.white)),
                        PieChartSectionData(value: 10, color: Colors.purple, title: 'Bills', radius: 50, titleStyle: TextStyle(color: Colors.white)),
                        PieChartSectionData(value: 5, color: Colors.red, title: 'Other', radius: 50, titleStyle: TextStyle(color: Colors.white)),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Cumulative Expenses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 1000,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                              return Text(months[value.toInt() % months.length]);
                            },
                            reservedSize: 32,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 4,
                          dotData: FlDotData(show: false),
                          spots: [FlSpot(0, 120), FlSpot(1, 320), FlSpot(2, 470), FlSpot(3, 770), FlSpot(4, 950), FlSpot(5, 1040)],
                        ),
                      ],
                    ),
                  ),
                ),
                // Add more charts or summary widgets here
              ],
            ),
          ),
        ),
      ),
    );
  }
}
