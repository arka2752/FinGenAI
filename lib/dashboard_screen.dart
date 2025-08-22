import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final AuthService _authService = AuthService();
  late List<TransactionModel> transactions = [];

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _chartController;
  late AnimationController _statsController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _chartAnimation;
  late Animation<double> _statsAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _chartController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _statsController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut));
    _chartAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _chartController, curve: Curves.easeOutBack));
    _statsAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _statsController, curve: Curves.easeOutCubic));
  }

  void _startAnimations() async {
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();
    _scaleController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _chartController.forward();
    _statsController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _chartController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  double calculateBalance(List<TransactionModel> transactions) {
    double balance = 0;
    for (var tx in transactions) {
      balance += (tx.type == "income" ? tx.amount : -tx.amount);
    }
    return balance;
  }

  double calculateIncome(List<TransactionModel> transactions) {
    return transactions
        .where((tx) => tx.type == "income")
        .fold(0, (sum, tx) => sum + tx.amount);
  }

  double calculateExpense(List<TransactionModel> transactions) {
    return transactions
        .where((tx) => tx.type == "expense")
        .fold(0, (sum, tx) => sum + tx.amount);
  }

  List<TransactionModel> getRecentTransactions() {
    final sortedTransactions = List<TransactionModel>.from(transactions);
    sortedTransactions.sort((a, b) => b.date.compareTo(a.date));
    return sortedTransactions.take(5).toList();
  }

  Map<String, double> getCategoryBreakdown() {
    final Map<String, double> categoryTotals = {};
    for (var tx in transactions.where((t) => t.type == "expense")) {
      categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0) + tx.amount;
    }
    return categoryTotals;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 650;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.surface,
              colorScheme.surfaceVariant.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildEnhancedAppBar(colorScheme, isSmallScreen),
              Expanded(
                child: StreamBuilder<List<TransactionModel>>(
                  stream: TransactionService().getUserTransactions(currentUser.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingState(colorScheme, isSmallScreen);
                    }

                    transactions = snapshot.data ?? [];
                    final balance = calculateBalance(transactions);
                    final income = calculateIncome(transactions);
                    final expense = calculateExpense(transactions);

                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(() {});
                      },
                      color: colorScheme.primary,
                      backgroundColor: colorScheme.surface,
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildWelcomeSection(colorScheme, isSmallScreen),
                                  SizedBox(height: isSmallScreen ? 16 : 24),
                                  _buildBalanceOverview(colorScheme, balance, income, expense, isSmallScreen),
                                  SizedBox(height: isSmallScreen ? 16 : 24),
                                  _buildQuickInsights(colorScheme, income, expense, isSmallScreen),
                                  SizedBox(height: isSmallScreen ? 16 : 24),
                                  _buildQuickActions(colorScheme, isSmallScreen),
                                  SizedBox(height: isSmallScreen ? 24 : 32),
                                  _buildSectionHeader(colorScheme, "Recent Activity", Icons.history, "${getRecentTransactions().length} transactions", isSmallScreen),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                ],
                              ),
                            ),
                          ),
                          if (transactions.isEmpty)
                            SliverFillRemaining(
                              child: _buildEmptyState(colorScheme, isSmallScreen),
                            )
                          else
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                  final recentTransactions = getRecentTransactions();
                                  if (index < recentTransactions.length) {
                                    return _buildTransactionCard(colorScheme, recentTransactions[index], index, isSmallScreen);
                                  }
                                  return null;
                                },
                                childCount: getRecentTransactions().length,
                              ),
                            ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 100),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme, bool isSmallScreen) {
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
            "Loading your dashboard...",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, bool isSmallScreen) {
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
                Icons.analytics_outlined,
                size: isSmallScreen ? 56 : 64,
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 20 : 24),
          Text(
            "No data to display",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 24 : 32),
            child: Text(
              "Start adding transactions to see\nyour financial insights",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedAppBar(ColorScheme colorScheme, bool isSmallScreen) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.fromLTRB(isSmallScreen ? 16 : 20, isSmallScreen ? 16 : 20, isSmallScreen ? 16 : 20, isSmallScreen ? 8 : 10),
        child: Row(
          children: [
            Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
              color: colorScheme.surface,
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: colorScheme.primary, size: isSmallScreen ? 18 : 20),
                onPressed: () => Navigator.pop(context),
                constraints: BoxConstraints(minWidth: isSmallScreen ? 40 : 44, minHeight: isSmallScreen ? 40 : 44),
              ),
            ),
            SizedBox(width: isSmallScreen ? 12 : 16),
            Expanded(
              child: Text(
                "Dashboard",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
              color: colorScheme.errorContainer,
              child: InkWell(
                onTap: () => _showLogoutDialog(colorScheme, isSmallScreen),
                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 20,
                    vertical: isSmallScreen ? 12 : 16,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.logout,
                        color: colorScheme.onErrorContainer,
                        size: isSmallScreen ? 18 : 20,
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      Text(
                        'Logout',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(ColorScheme colorScheme, bool isSmallScreen) {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Good ${_getTimeOfDay()},",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          SizedBox(height: isSmallScreen ? 2 : 4),
          Text(
            "${currentUser.displayName ?? 'User'}!",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            "Here's your financial overview",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Morning";
    if (hour < 17) return "Afternoon";
    return "Evening";
  }

  Widget _buildBalanceOverview(ColorScheme colorScheme, double balance, double income, double expense, bool isSmallScreen) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
        color: colorScheme.surface,
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
            border: Border.all(color: colorScheme.outline.withOpacity(0.12), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.account_balance_wallet, color: colorScheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Total Balance",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (balance >= 0 ? Colors.green : Colors.red).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      balance >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: balance >= 0 ? Colors.green : Colors.red,
                      size: 16,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  "\$${balance.toStringAsFixed(2)}",
                  key: ValueKey(balance),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    shadows: [
                      Shadow(
                        color: colorScheme.shadow.withOpacity(0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 24),
              Row(
                children: [
                  Expanded(
                    child: _buildBalanceItem(colorScheme, "Income", income, Colors.green, Icons.arrow_downward, isSmallScreen),
                  ),
                  Container(
                    width: 1,
                    height: isSmallScreen ? 32 : 40,
                    color: colorScheme.outline.withOpacity(0.1),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  Expanded(
                    child: _buildBalanceItem(colorScheme, "Expenses", expense, Colors.red, Icons.arrow_upward, isSmallScreen),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceItem(ColorScheme colorScheme, String title, double amount, Color color, IconData icon, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: isSmallScreen ? 14 : 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            "\$${amount.toStringAsFixed(2)}",
            key: ValueKey(amount),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickInsights(ColorScheme colorScheme, double income, double expense, bool isSmallScreen) {
    final savingsRate = income > 0 ? ((income - expense) / income * 100) : 0;
    final spendingTrend = expense > income ? "High" : expense > income * 0.7 ? "Moderate" : "Low";

    return AnimatedBuilder(
      animation: _statsAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _statsAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - _statsAnimation.value)),
            child: Row(
              children: [
                Expanded(
                  child: _buildInsightCard(colorScheme, "Savings Rate", "${savingsRate.toStringAsFixed(1)}%", Icons.savings_outlined,
                      savingsRate >= 20 ? Colors.green : savingsRate >= 10 ? Colors.orange : Colors.red, isSmallScreen),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInsightCard(colorScheme, "Spending", spendingTrend, Icons.trending_up_outlined,
                      spendingTrend == "Low" ? Colors.green : spendingTrend == "Moderate" ? Colors.orange : Colors.red, isSmallScreen),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInsightCard(ColorScheme colorScheme, String title, String value, IconData icon, Color color, bool isSmallScreen) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
      color: colorScheme.surface,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
          border: Border.all(color: colorScheme.outline.withOpacity(0.12), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: isSmallScreen ? 18 : 20),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 10 : 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: isSmallScreen ? 2 : 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(ColorScheme colorScheme, bool isSmallScreen) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Actions",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(colorScheme, "Add Transaction", Icons.add_circle_outline, colorScheme.primary, () => _navigateToAddTransaction(), isSmallScreen),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(colorScheme, "View All", Icons.list_alt_outlined, colorScheme.secondary, () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: animation.drive(
                          Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                              .chain(CurveTween(curve: Curves.easeInOut)),
                        ),
                        child: child,
                      );
                    },
                  ),
                ), isSmallScreen),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  colorScheme, 
                  "Logout", 
                  Icons.logout, 
                  colorScheme.error, 
                  () => _showLogoutDialog(colorScheme, isSmallScreen), 
                  isSmallScreen
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(ColorScheme colorScheme, String title, IconData icon, Color color, VoidCallback onTap, bool isSmallScreen) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
      color: colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
            border: Border.all(color: colorScheme.outline.withOpacity(0.12), width: 1),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                ),
                child: Icon(icon, color: color, size: isSmallScreen ? 22 : 24),
              ),
              SizedBox(height: isSmallScreen ? 10 : 12),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ColorScheme colorScheme, String title, IconData icon, String subtitle, bool isSmallScreen) {
    return Row(
      children: [
        Icon(icon, color: colorScheme.onSurfaceVariant, size: isSmallScreen ? 18 : 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(ColorScheme colorScheme, TransactionModel transaction, int index, bool isSmallScreen) {
    return AnimatedBuilder(
      animation: _statsAnimation,
      builder: (context, child) {
        final delay = index * 0.1;
        final animationValue = (_statsAnimation.value - delay).clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(0, 30 * (1 - animationValue)),
          child: Opacity(
            opacity: animationValue,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
              color: colorScheme.surface,
              child: InkWell(
                borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
                onTap: () {},
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                        decoration: BoxDecoration(
                          color: (transaction.type == "income" ? Colors.green : Colors.red).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                        ),
                        child: Icon(
                          transaction.type == "income" ? Icons.arrow_downward : Icons.arrow_upward,
                          color: transaction.type == "income" ? Colors.green : Colors.red,
                          size: isSmallScreen ? 16 : 18,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transaction.title,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isSmallScreen ? 2 : 4),
                            Text(
                              transaction.date.toLocal().toString().split(' ')[0],
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "\$${transaction.amount.toStringAsFixed(2)}",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: transaction.type == "income" ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog(ColorScheme colorScheme, bool isSmallScreen) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          elevation: 24,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.logout, color: colorScheme.onErrorContainer, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Sign Out',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to sign out?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You\'ll need to sign in again to access your dashboard.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.8)
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.primary)
              ),
            ),
            Material(
              color: colorScheme.error,
              borderRadius: BorderRadius.circular(8),
              child: TextButton(
                onPressed: () async {
                  try {
                    Navigator.pop(context); // Close dialog first
                    await _authService.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error signing out: ${e.toString()}'),
                          backgroundColor: colorScheme.error,
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  'Sign Out',
                  style: TextStyle(color: colorScheme.onError)
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToAddTransaction() {
    // Navigate back to HomeScreen and trigger add transaction
    Navigator.pop(context);
    // You might want to pass a flag or use a callback to trigger the add transaction sheet
  }
} 