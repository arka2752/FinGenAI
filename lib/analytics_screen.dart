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
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 650;
    final isExtraSmallScreen = size.height < 500;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildMaterialAppBar(colorScheme, isSmallScreen, isExtraSmallScreen),
      body: RefreshIndicator(
        onRefresh: _loadAnalytics,
        color: colorScheme.primary,
        backgroundColor: colorScheme.surface,
        child: _buildBody(colorScheme, isSmallScreen, isExtraSmallScreen),
      ),
    );
  }

  PreferredSizeWidget _buildMaterialAppBar(ColorScheme colorScheme, bool isSmallScreen, bool isExtraSmallScreen) {
    return AppBar(
      title: Text(
        isExtraSmallScreen ? "Analytics" : "Analytics & Insights",
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      backgroundColor: colorScheme.surface,
      elevation: 8,
      shadowColor: colorScheme.shadow.withOpacity(0.3),
      actions: [
        Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
          color: colorScheme.surface,
          child: IconButton(
            icon: Icon(
              Icons.refresh,
              color: colorScheme.primary,
              size: isSmallScreen ? 20 : 24,
            ),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh Data',
            constraints: BoxConstraints(
              minWidth: isSmallScreen ? 40 : 44,
              minHeight: isSmallScreen ? 40 : 44,
            ),
          ),
        ),
        SizedBox(width: isSmallScreen ? 8 : 12),
      ],
    );
  }

  Widget _buildBody(ColorScheme colorScheme, bool isSmallScreen, bool isExtraSmallScreen) {
    if (loading) {
      return _buildLoadingState(colorScheme, isSmallScreen, isExtraSmallScreen);
    }

    if (error != null) {
      return _buildErrorState(colorScheme, isSmallScreen, isExtraSmallScreen);
    }

    final hasNoData = (expensesByCategory.isEmpty) && (monthlyData.isEmpty);
    if (hasNoData) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(isSmallScreen ? 18 : 20),
                color: colorScheme.surface,
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isSmallScreen ? 18 : 20),
                    border: Border.all(color: colorScheme.outline.withOpacity(0.1), width: 1),
                  ),
                  child: Icon(
                    Icons.insights_outlined,
                    size: isSmallScreen ? 56 : 64,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              Text(
                'No analytics yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              Text(
                'Add some transactions to see charts and insights here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                color: colorScheme.primary,
                child: TextButton(
                  onPressed: _loadAnalytics,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16 : 20,
                      vertical: isSmallScreen ? 10 : 12,
                    ),
                  ),
                  child: Text(
                    'Refresh',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(colorScheme, isSmallScreen, isExtraSmallScreen),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  _buildInfoRow(colorScheme, isSmallScreen),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  _buildExpensesChart(colorScheme, isSmallScreen, isExtraSmallScreen),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  _buildIncomeExpenseChart(colorScheme, isSmallScreen, isExtraSmallScreen),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme, bool isSmallScreen, bool isExtraSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
            color: colorScheme.surface,
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                border: Border.all(color: colorScheme.outline.withOpacity(0.1), width: 1),
              ),
              child: CircularProgressIndicator(
                color: colorScheme.primary,
                strokeWidth: 3,
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            'Loading analytics...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme, bool isSmallScreen, bool isExtraSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(isSmallScreen ? 18 : 20),
            color: colorScheme.surface,
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isSmallScreen ? 18 : 20),
                border: Border.all(color: colorScheme.outline.withOpacity(0.1), width: 1),
              ),
              child: Icon(
                Icons.error_outline,
                size: isSmallScreen ? 56 : 64,
                color: colorScheme.error,
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Text(
            'Failed to load analytics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 24 : 32),
            child: Text(
              error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
            color: colorScheme.primary,
            child: ElevatedButton(
              onPressed: _loadAnalytics,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 20 : 24,
                  vertical: isSmallScreen ? 12 : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                ),
              ),
              child: Text(
                'Retry',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ColorScheme colorScheme, bool isSmallScreen, bool isExtraSmallScreen) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Stack vertically on small screens
          return Column(
            children: [
              _buildSummaryCard(
                colorScheme,
                'Total Income',
                '₹${totalIncome.toStringAsFixed(2)}',
                Colors.green,
                Icons.trending_up,
                isSmallScreen,
                isExtraSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              _buildSummaryCard(
                colorScheme,
                'Total Expenses',
                '₹${totalExpenses.toStringAsFixed(2)}',
                Colors.red,
                Icons.trending_down,
                isSmallScreen,
                isExtraSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              _buildSummaryCard(
                colorScheme,
                'Net Savings',
                '₹${netSavings.toStringAsFixed(2)}',
                netSavings >= 0 ? Colors.blue : Colors.orange,
                netSavings >= 0 ? Icons.savings : Icons.warning,
                isSmallScreen,
                isExtraSmallScreen,
              ),
            ],
          );
        }
        
        // Row layout for larger screens
        return Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                colorScheme,
                'Total Income',
                '₹${totalIncome.toStringAsFixed(2)}',
                Colors.green,
                Icons.trending_up,
                isSmallScreen,
                isExtraSmallScreen,
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            Expanded(
              child: _buildSummaryCard(
                colorScheme,
                'Total Expenses',
                '₹${totalExpenses.toStringAsFixed(2)}',
                Colors.red,
                Icons.trending_down,
                isSmallScreen,
                isExtraSmallScreen,
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            Expanded(
              child: _buildSummaryCard(
                colorScheme,
                'Net Savings',
                '₹${netSavings.toStringAsFixed(2)}',
                netSavings >= 0 ? Colors.blue : Colors.orange,
                netSavings >= 0 ? Icons.savings : Icons.warning,
                isSmallScreen,
                isExtraSmallScreen,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(ColorScheme colorScheme, String title, String value, Color color, IconData icon, bool isSmallScreen, bool isExtraSmallScreen) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
      color: colorScheme.surface,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          border: Border.all(color: colorScheme.outline.withOpacity(0.1), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: isSmallScreen ? 20 : 24,
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isSmallScreen ? 2 : 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ColorScheme colorScheme, bool isSmallScreen) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem(colorScheme, 'Categories', expensesByCategory.length, Icons.category, isSmallScreen),
                  _buildInfoItem(colorScheme, 'Months', monthlyData.length, Icons.calendar_today, isSmallScreen),
                ],
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem(colorScheme, 'Income', totalIncome.toInt(), Icons.trending_up, isSmallScreen),
                  _buildInfoItem(colorScheme, 'Expenses', totalExpenses.toInt(), Icons.trending_down, isSmallScreen),
                ],
              ),
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildInfoItem(colorScheme, 'Categories', expensesByCategory.length, Icons.category, isSmallScreen),
            _buildInfoItem(colorScheme, 'Months', monthlyData.length, Icons.calendar_today, isSmallScreen),
            _buildInfoItem(colorScheme, 'Income', totalIncome.toInt(), Icons.trending_up, isSmallScreen),
            _buildInfoItem(colorScheme, 'Expenses', totalExpenses.toInt(), Icons.trending_down, isSmallScreen),
          ],
        );
      },
    );
  }

  Widget _buildInfoItem(ColorScheme colorScheme, String label, int value, IconData icon, bool isSmallScreen) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
      color: colorScheme.surface,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
          border: Border.all(color: colorScheme.outline.withOpacity(0.1), width: 1),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: colorScheme.primary,
              size: isSmallScreen ? 20 : 24,
            ),
            SizedBox(height: isSmallScreen ? 4 : 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 2 : 4),
            Text(
              value.toString(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesChart(ColorScheme colorScheme, bool isSmallScreen, bool isExtraSmallScreen) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
      color: colorScheme.surface,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
          border: Border.all(color: colorScheme.outline.withOpacity(0.1), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart,
                  color: colorScheme.primary,
                  size: isSmallScreen ? 20 : 24,
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Expanded(
                  child: Text(
                    "Expenses by Category",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              "Total: ₹${totalExpenses.toStringAsFixed(2)}",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            expensesByCategory.isEmpty
                ? SizedBox(
              height: isSmallScreen ? 160 : 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox,
                      size: isSmallScreen ? 48 : 64,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    Text(
                      'No expense data available',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
                : PieChartWidget(
              data: expensesByCategory,
              size: isSmallScreen ? 220 : 280,
              centerText: '${expensesByCategory.length}\nCategories',
              centerTextStyle: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
              onSectionTap: (category, amount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$category: ₹${amount.toStringAsFixed(2)} (${(amount / totalExpenses * 100).toStringAsFixed(1)}%)',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: colorScheme.surface,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeExpenseChart(ColorScheme colorScheme, bool isSmallScreen, bool isExtraSmallScreen) {
    if (monthlyData.isEmpty) {
      return Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        color: colorScheme.surface,
        child: Container(
          height: isSmallScreen ? 240 : 300,
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
            border: Border.all(color: colorScheme.outline.withOpacity(0.1), width: 1),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.show_chart,
                  size: isSmallScreen ? 48 : 64,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                Text(
                  'No monthly data available',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
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

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
      color: colorScheme.surface,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
          border: Border.all(color: colorScheme.outline.withOpacity(0.1), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.show_chart,
                  color: colorScheme.primary,
                  size: isSmallScreen ? 20 : 24,
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Expanded(
                  child: Text(
                    "Monthly Income vs Expenses",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Row(
              children: [
                Container(
                  width: isSmallScreen ? 12 : 16,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Text(
                  'Income',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 16 : 20),
                Container(
                  width: isSmallScreen ? 12 : 16,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Text(
                  'Expenses',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            SizedBox(
              height: isSmallScreen ? 220 : 280,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: colorScheme.outline.withOpacity(0.2), strokeWidth: 1),
                    getDrawingVerticalLine: (value) =>
                        FlLine(color: colorScheme.outline.withOpacity(0.2), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: colorScheme.outline.withOpacity(0.2), width: 1),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: isSmallScreen ? 32 : 40,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedKeys.length) {
                            return Padding(
                              padding: EdgeInsets.only(top: isSmallScreen ? 6 : 8),
                              child: Text(
                                sortedKeys[index],
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 12,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurfaceVariant,
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
                        reservedSize: isSmallScreen ? 48 : 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '₹${(value / 1000).toStringAsFixed(0)}K',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 9 : 11,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
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
                      barWidth: isSmallScreen ? 2 : 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: isSmallScreen ? 3 : 4,
                          color: colorScheme.surface,
                          strokeWidth: isSmallScreen ? 1.5 : 2,
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
                      barWidth: isSmallScreen ? 2 : 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: isSmallScreen ? 3 : 4,
                          color: colorScheme.surface,
                          strokeWidth: isSmallScreen ? 1.5 : 2,
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
                      tooltipRoundedRadius: isSmallScreen ? 6 : 8,
                      tooltipPadding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                      getTooltipItems: (touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          final monthIndex = barSpot.x.toInt();
                          final month = sortedKeys[monthIndex];
                          final isIncome = barSpot.barIndex == 0;

                          return LineTooltipItem(
                            '$month\n${isIncome ? 'Income' : 'Expense'}: ₹${barSpot.y.toStringAsFixed(0)}',
                            TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
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
