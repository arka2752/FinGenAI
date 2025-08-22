import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'models/transaction_model.dart';
import 'services/transaction_service.dart';
import 'chart_widget.dart';

class AnalyticsScreenV2 extends StatelessWidget {
  final String userId;
  const AnalyticsScreenV2({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 650;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 8,
        title: Text(
          'Analytics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Help',
            icon: Icon(Icons.help_outline, color: colorScheme.primary),
            onPressed: () => _showHelpDialog(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: TransactionService().getUserTransactions(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading(context, isSmallScreen);
          }
          if (snapshot.hasError) {
            return _buildError(context, snapshot.error.toString(), isSmallScreen);
          }

          final transactions = snapshot.data ?? const <TransactionModel>[];
          final aggregates = _computeAggregates(transactions);

          if (transactions.isEmpty) {
            return _buildEmpty(context, isSmallScreen);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final children = <Widget>[
                _AnimatedSection(
                  index: 0,
                  child: _SummaryRow(
                    totalIncome: aggregates.totalIncome,
                    totalExpenses: aggregates.totalExpenses,
                    netSavings: aggregates.netSavings,
                    isSmall: isSmallScreen,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 16 : 24),
                _AnimatedSection(
                  index: 1,
                  child: _InfoRow(
                    categoriesCount: aggregates.expensesByCategory.length,
                    monthsCount: aggregates.monthly.keys.length,
                    isSmall: isSmallScreen,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 16 : 24),
                _AnimatedSection(
                  index: 2,
                  child: _ExpensesPieCard(
                    totalExpenses: aggregates.totalExpenses,
                    data: aggregates.expensesByCategory,
                    isSmall: isSmallScreen,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 16 : 24),
                _AnimatedSection(
                  index: 3,
                  child: _IncomeExpenseLineCard(
                    monthly: aggregates.monthly,
                    isSmall: isSmallScreen,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 16 : 24),
              ];

              return SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        elevation: 24,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('What you are seeing', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HelpItem(icon: Icons.pie_chart, title: 'Expenses by Category', body: 'Breakdown of your spending per category.'),
              const SizedBox(height: 12),
              _HelpItem(icon: Icons.show_chart, title: 'Monthly Trends', body: 'Income vs. expenses across months.'),
              const SizedBox(height: 12),
              _HelpItem(icon: Icons.savings, title: 'Summary', body: 'Totals for income, expenses, and net savings.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: cs.primary)),
          ),
        ],
      ),
    );
  }

  _Aggregates _computeAggregates(List<TransactionModel> txs) {
    final Map<String, double> byCategory = {};
    final Map<String, Map<String, double>> monthly = {};
    double totalIncome = 0;
    double totalExpenses = 0;

    for (final tx in txs) {
      final type = tx.type;
      if (type == 'income') {
        totalIncome += tx.amount;
      } else if (type == 'expense') {
        totalExpenses += tx.amount;
        final cat = (tx.category).isEmpty ? 'Uncategorized' : tx.category;
        byCategory[cat] = (byCategory[cat] ?? 0) + tx.amount;
      }
      final monthKey = "${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}";
      monthly[monthKey] ??= {'income': 0, 'expense': 0};
      if (type == 'income' || type == 'expense') {
        monthly[monthKey]![type] = (monthly[monthKey]![type] ?? 0) + tx.amount;
      }
    }

    return _Aggregates(
      expensesByCategory: byCategory,
      monthly: monthly,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
    );
  }

  Widget _buildLoading(BuildContext context, bool isSmall) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(isSmall ? 16 : 20),
            color: cs.surface,
            child: Padding(
              padding: EdgeInsets.all(isSmall ? 16 : 20),
              child: CircularProgressIndicator(color: cs.primary, strokeWidth: 3),
            ),
          ),
          SizedBox(height: isSmall ? 12 : 16),
          Text('Loading analytics...', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message, bool isSmall) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 16 : 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: isSmall ? 56 : 64, color: cs.error),
            SizedBox(height: isSmall ? 12 : 16),
            Text('Failed to load analytics', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)),
            SizedBox(height: isSmall ? 6 : 8),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, bool isSmall) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 16 : 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights_outlined, size: isSmall ? 56 : 64, color: cs.onSurfaceVariant.withOpacity(0.8)),
            SizedBox(height: isSmall ? 12 : 16),
            Text('No analytics yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)),
            SizedBox(height: isSmall ? 6 : 8),
            Text('Add transactions to see charts and insights.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _AnimatedSection extends StatelessWidget {
  final Widget child;
  final int index;
  const _AnimatedSection({required this.child, required this.index});
  @override
  Widget build(BuildContext context) {
    final offset = 20.0;
    final duration = Duration(milliseconds: 350 + (index * 100));
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offset * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon; final String title; final String body;
  const _HelpItem({required this.icon, required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: cs.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
              const SizedBox(height: 4),
              Text(body, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        )
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final double totalIncome;
  final double totalExpenses;
  final double netSavings;
  final bool isSmall;
  const _SummaryRow({required this.totalIncome, required this.totalExpenses, required this.netSavings, required this.isSmall});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cards = [
      _SummaryCard(label: 'Income', value: totalIncome, color: Colors.green, icon: Icons.trending_up, isSmall: isSmall),
      _SummaryCard(label: 'Expenses', value: totalExpenses, color: Colors.red, icon: Icons.trending_down, isSmall: isSmall),
      _SummaryCard(label: 'Net', value: netSavings, color: netSavings >= 0 ? cs.primary : Colors.orange, icon: netSavings >= 0 ? Icons.savings : Icons.warning, isSmall: isSmall),
    ];

    if (MediaQuery.of(context).size.width < 600) {
      return Column(
        children: [
          cards[0], SizedBox(height: isSmall ? 8 : 12), cards[1], SizedBox(height: isSmall ? 8 : 12), cards[2],
        ],
      );
    }
    return Row(children: [Expanded(child: cards[0]), SizedBox(width: isSmall ? 8 : 12), Expanded(child: cards[1]), SizedBox(width: isSmall ? 8 : 12), Expanded(child: cards[2])]);
  }
}

class _SummaryCard extends StatelessWidget {
  final String label; final double value; final Color color; final IconData icon; final bool isSmall;
  const _SummaryCard({required this.label, required this.value, required this.color, required this.icon, required this.isSmall});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
      color: cs.surface,
      child: Container(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
          border: Border.all(color: cs.outline.withOpacity(0.1), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmall ? 8 : 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: isSmall ? 18 : 20),
            ),
            SizedBox(width: isSmall ? 10 : 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
                SizedBox(height: isSmall ? 2 : 4),
                Text('₹${value.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final int categoriesCount; final int monthsCount; final bool isSmall;
  const _InfoRow({required this.categoriesCount, required this.monthsCount, required this.isSmall});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget chip(IconData icon, String label, String value) => Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(isSmall ? 10 : 12),
      color: cs.surface,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 14, vertical: isSmall ? 8 : 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isSmall ? 10 : 12),
          border: Border.all(color: cs.outline.withOpacity(0.1), width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: cs.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: cs.primary, size: isSmall ? 16 : 18),
          ),
          SizedBox(width: isSmall ? 8 : 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
          ]),
        ]),
      ),
    );

    if (MediaQuery.of(context).size.width < 600) {
      return Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [chip(Icons.category, 'Categories', '$categoriesCount'), chip(Icons.calendar_today, 'Months', '$monthsCount')]),
      ]);
    }
    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [chip(Icons.category, 'Categories', '$categoriesCount'), chip(Icons.calendar_today, 'Months', '$monthsCount')]);
  }
}

class _ExpensesPieCard extends StatelessWidget {
  final double totalExpenses; final Map<String, double> data; final bool isSmall;
  const _ExpensesPieCard({required this.totalExpenses, required this.data, required this.isSmall});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(isSmall ? 16 : 20),
      color: cs.surface,
      child: Container(
        padding: EdgeInsets.all(isSmall ? 16 : 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isSmall ? 16 : 20),
          border: Border.all(color: cs.outline.withOpacity(0.1), width: 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(Icons.pie_chart, color: cs.primary, size: isSmall ? 20 : 24), SizedBox(width: isSmall ? 6 : 8), Expanded(child: Text('Expenses by Category', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface), overflow: TextOverflow.ellipsis))]),
          SizedBox(height: isSmall ? 8 : 10),
          Text('Total: ₹${totalExpenses.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          SizedBox(height: isSmall ? 14 : 18),
          PieChartWidget(
            data: data,
            size: isSmall ? 220 : 280,
            centerText: '${data.length}\nCategories',
            centerTextStyle: TextStyle(fontSize: isSmall ? 14 : 16, fontWeight: FontWeight.bold, color: cs.primary),
            onSectionTap: (category, amount) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: cs.surface,
                content: Text('$category: ₹${amount.toStringAsFixed(2)}', style: TextStyle(color: cs.onSurface)),
              ));
            },
          ),
        ]),
      ),
    );
  }
}

class _IncomeExpenseLineCard extends StatelessWidget {
  final Map<String, Map<String, double>> monthly; final bool isSmall;
  const _IncomeExpenseLineCard({required this.monthly, required this.isSmall});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (monthly.isEmpty) {
      return Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(isSmall ? 16 : 20),
        color: cs.surface,
        child: Container(
          height: isSmall ? 220 : 280,
          padding: EdgeInsets.all(isSmall ? 16 : 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isSmall ? 16 : 20),
            border: Border.all(color: cs.outline.withOpacity(0.1), width: 1),
          ),
          child: Center(child: Text('No monthly data', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))),
        ),
      );
    }

    final sortedKeys = monthly.keys.toList()..sort();
    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    for (int i = 0; i < sortedKeys.length; i++) {
      final data = monthly[sortedKeys[i]]!;
      incomeSpots.add(FlSpot(i.toDouble(), (data['income'] ?? 0)));
      expenseSpots.add(FlSpot(i.toDouble(), (data['expense'] ?? 0)));
    }

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(isSmall ? 16 : 20),
      color: cs.surface,
      child: Container(
        padding: EdgeInsets.all(isSmall ? 16 : 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isSmall ? 16 : 20),
          border: Border.all(color: cs.outline.withOpacity(0.1), width: 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(Icons.show_chart, color: cs.primary, size: isSmall ? 20 : 24), SizedBox(width: isSmall ? 6 : 8), Expanded(child: Text('Monthly Income vs Expenses', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface), overflow: TextOverflow.ellipsis))]),
          SizedBox(height: isSmall ? 10 : 12),
          SizedBox(
            height: isSmall ? 220 : 280,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (value) => FlLine(color: cs.outline.withOpacity(0.2), strokeWidth: 1),
                  getDrawingVerticalLine: (value) => FlLine(color: cs.outline.withOpacity(0.2), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: cs.outline.withOpacity(0.2), width: 1)),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isSmall ? 32 : 40,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i >= 0 && i < sortedKeys.length) {
                          return Padding(
                            padding: EdgeInsets.only(top: isSmall ? 6 : 8),
                            child: Text(sortedKeys[i], style: TextStyle(fontSize: isSmall ? 10 : 12, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant)),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isSmall ? 48 : 60,
                      getTitlesWidget: (value, meta) => Text('₹${(value / 1000).toStringAsFixed(0)}K', style: TextStyle(fontSize: isSmall ? 9 : 11, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant)),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: incomeSpots,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: isSmall ? 2 : 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: isSmall ? 3 : 4, color: cs.surface, strokeWidth: isSmall ? 1.5 : 2, strokeColor: Colors.green)),
                    belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.1)),
                  ),
                  LineChartBarData(
                    spots: expenseSpots,
                    isCurved: true,
                    color: Colors.red,
                    barWidth: isSmall ? 2 : 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: isSmall ? 3 : 4, color: cs.surface, strokeWidth: isSmall ? 1.5 : 2, strokeColor: Colors.red)),
                    belowBarData: BarAreaData(show: true, color: Colors.red.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Aggregates {
  final Map<String, double> expensesByCategory;
  final Map<String, Map<String, double>> monthly;
  final double totalIncome;
  final double totalExpenses;
  double get netSavings => totalIncome - totalExpenses;
  _Aggregates({required this.expensesByCategory, required this.monthly, required this.totalIncome, required this.totalExpenses});
} 