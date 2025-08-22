import 'package:flutter/material.dart';
import '../services/transaction_service.dart';
import 'chart_widget.dart'; // Updated import
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  final String userId;
  const AnalyticsScreen({super.key, required this.userId});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final TransactionService _service = TransactionService();
  Map<String, double> expensesByCategory = {};
  Map<String, Map<String, double>> monthlyData = {};
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final catData = await _service.getExpensesByCategory(widget.userId);
      final monthData = await _service.getMonthlyIncomeExpense(widget.userId);

      setState(() {
        expensesByCategory = catData;
        monthlyData = monthData;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  double get totalExpenses => expensesByCategory.values.fold(0.0, (sum, value) => sum + value);

  double get totalIncome {
    return monthlyData.values.fold(0.0, (sum, monthData) {
      return sum + (monthData['income'] ?? 0);
    });
  }

  double get netSavings => totalIncome - totalExpenses;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Analytics & Insights"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnalytics,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading analytics...'),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load analytics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAnalytics,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildExpensesChart(),
          const SizedBox(height: 24),
          _buildIncomeExpenseChart(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Income',
            '₹${totalIncome.toStringAsFixed(2)}',
            Colors.green,
            Icons.trending_up,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Total Expenses',
            '₹${totalExpenses.toStringAsFixed(2)}',
            Colors.red,
            Icons.trending_down,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Net Savings',
            '₹${netSavings.toStringAsFixed(2)}',
            netSavings >= 0 ? Colors.blue : Colors.orange,
            netSavings >= 0 ? Icons.savings : Icons.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesChart() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  "Expenses by Category",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Total: ₹${totalExpenses.toStringAsFixed(2)}",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            expensesByCategory.isEmpty
                ? SizedBox(
              height: 200,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No expense data available'),
                  ],
                ),
              ),
            )
                : PieChartWidget(
              data: expensesByCategory,
              size: 280,
              centerText: '${expensesByCategory.length}\nCategories',
              centerTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
              onSectionTap: (category, amount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$category: ₹${amount.toStringAsFixed(2)} (${(amount / totalExpenses * 100).toStringAsFixed(1)}%)',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeExpenseChart() {
    if (monthlyData.isEmpty) {
      return Card(
        elevation: 3,
        child: Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No monthly data available'),
              ],
            ),
          ),
        ),
      );
    }

    final sortedKeys = monthlyData.keys.toList()..sort();
    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];

    for (int i = 0; i < sortedKeys.length; i++) {
      final month = sortedKeys[i];
      final data = monthlyData[month]!;
      incomeSpots.add(FlSpot(i.toDouble(), data['income'] ?? 0));
      expenseSpots.add(FlSpot(i.toDouble(), data['expense'] ?? 0));
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  "Monthly Income vs Expenses",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Income', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 20),
                Container(
                  width: 16,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Expenses', style: TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 280,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: Colors.grey[300]!, strokeWidth: 1),
                    getDrawingVerticalLine: (value) =>
                        FlLine(color: Colors.grey[300]!, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedKeys.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                sortedKeys[index],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                          return const Text("");
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '₹${(value / 1000).toStringAsFixed(0)}K',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: incomeSpots,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.green,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                    LineChartBarData(
                      spots: expenseSpots,
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.red,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.red.withOpacity(0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.all(8),
                      getTooltipItems: (touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          final monthIndex = barSpot.x.toInt();
                          final month = sortedKeys[monthIndex];
                          final isIncome = barSpot.barIndex == 0;

                          return LineTooltipItem(
                            '$month\n${isIncome ? 'Income' : 'Expense'}: ₹${barSpot.y.toStringAsFixed(0)}',
                            TextStyle(
                              color: Colors.white, // text color inside tooltip
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: '',
                                style: TextStyle(
                                  backgroundColor: isIncome ? Colors.green : Colors.red, // tooltip background
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),


                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
