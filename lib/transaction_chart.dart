import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'finance_model.dart';

class TransactionChart extends StatelessWidget {
  final List<Transaction> transactions;
  final int daysToShow;

  const TransactionChart({
    super.key,
    required this.transactions,
    this.daysToShow = 7,
  });

  List<Map<String, dynamic>> _getFilteredData() {
    final now = DateTime.now();
    
    if (daysToShow == 7) {
      // For 7 days, show daily data
      Map<DateTime, Map<String, dynamic>> dailyTotals = {};
      
      // Initialize all dates in the range with zero values
      for (int i = 0; i < daysToShow; i++) {
        final date = now.subtract(Duration(days: i));
        dailyTotals[DateTime(date.year, date.month, date.day)] = {
          'income': 0.0,
          'expense': 0.0,
          'startDate': date,
          'endDate': date,
        };
      }
      
      // Sum up transactions for each day
      for (var transaction in transactions) {
        final date = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );
        
        if (dailyTotals.containsKey(date)) {
          if (transaction.type == 'Income') {
            dailyTotals[date]!['income'] = (dailyTotals[date]!['income'] as double) + transaction.amount;
          } else {
            dailyTotals[date]!['expense'] = (dailyTotals[date]!['expense'] as double) + transaction.amount;
          }
        }
      }
      
      return dailyTotals.entries
          .map((entry) => {
                'date': entry.key,
                'income': entry.value['income'] as double,
                'expense': entry.value['expense'] as double,
                'startDate': entry.value['startDate'] as DateTime,
                'endDate': entry.value['endDate'] as DateTime,
              })
          .toList()
        ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    } else {
      // For 30 days, show 5-day intervals
      Map<DateTime, Map<String, dynamic>> intervalTotals = {};
      
      // Initialize 5-day intervals
      for (int i = 0; i < daysToShow; i += 5) {
        final endDate = now.subtract(Duration(days: i));
        final startDate = endDate.subtract(const Duration(days: 4));
        intervalTotals[startDate] = {
          'income': 0.0,
          'expense': 0.0,
          'startDate': startDate,
          'endDate': endDate,
        };
      }
      
      // Add the remaining days if any
      final remainingDays = daysToShow % 5;
      if (remainingDays > 0) {
        final lastEndDate = now.subtract(Duration(days: daysToShow - remainingDays));
        final lastStartDate = lastEndDate.subtract(Duration(days: remainingDays - 1));
        intervalTotals[lastStartDate] = {
          'income': 0.0,
          'expense': 0.0,
          'startDate': lastStartDate,
          'endDate': lastEndDate,
        };
      }
      
      // Sum up transactions for each interval
      for (var transaction in transactions) {
        final date = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );
        
        // Find the interval this transaction belongs to
        for (var entry in intervalTotals.entries) {
          final startDate = entry.key;
          final endDate = entry.value['endDate'] as DateTime;
          if (date.isAtSameMomentAs(startDate) || 
              date.isAtSameMomentAs(endDate) ||
              (date.isAfter(startDate) && date.isBefore(endDate))) {
            if (transaction.type == 'Income') {
              entry.value['income'] = (entry.value['income'] as double) + transaction.amount;
            } else {
              entry.value['expense'] = (entry.value['expense'] as double) + transaction.amount;
            }
            break;
          }
        }
      }
      
      return intervalTotals.entries
          .map((entry) => {
                'date': entry.key,
                'income': entry.value['income'] as double,
                'expense': entry.value['expense'] as double,
                'startDate': entry.value['startDate'] as DateTime,
                'endDate': entry.value['endDate'] as DateTime,
              })
          .toList()
        ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _getFilteredData();
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: filteredData.fold<double>(
            0,
            (max, item) => [item['income']!, item['expense']!].reduce((a, b) => a > b ? a : b) > max
                ? [item['income']!, item['expense']!].reduce((a, b) => a > b ? a : b)
                : max,
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.blueGrey,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final startDate = filteredData[groupIndex]['startDate'] as DateTime;
                final endDate = filteredData[groupIndex]['endDate'] as DateTime;
                final income = filteredData[groupIndex]['income'] as double;
                final expense = filteredData[groupIndex]['expense'] as double;
                
                return BarTooltipItem(
                  '${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd').format(endDate)}\n'
                  'Income: \$${income.toStringAsFixed(2)}\n'
                  'Expense: \$${expense.toStringAsFixed(2)}',
                  const TextStyle(color: Colors.white),
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
                  if (value.toInt() >= filteredData.length) return const SizedBox();
                  final startDate = filteredData[value.toInt()]['startDate'] as DateTime;
                  final endDate = filteredData[value.toInt()]['endDate'] as DateTime;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${DateFormat('MMM dd').format(startDate)}\n${DateFormat('MMM dd').format(endDate)}',
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '\$${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300),
          ),
          barGroups: List.generate(
            filteredData.length,
            (index) => BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: filteredData[index]['income'] as double,
                  color: Colors.green,
                  width: 8,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                BarChartRodData(
                  toY: filteredData[index]['expense'] as double,
                  color: Colors.red,
                  width: 8,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 