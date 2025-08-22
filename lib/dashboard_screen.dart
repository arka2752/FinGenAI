import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import 'home_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser!;
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1a237e),
              const Color(0xFF3949ab),
              const Color(0xFF5e35b1),
              const Color(0xFF8e24aa),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildEnhancedAppBar(),
              Expanded(
                child: StreamBuilder<List<TransactionModel>>(
                  stream: TransactionService().getUserTransactions(currentUser.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingState();
                    }

                    transactions = snapshot.data ?? [];
                    final balance = calculateBalance(transactions);
                    final income = calculateIncome(transactions);
                    final expense = calculateExpense(transactions);

                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(() {});
                      },
                      color: Colors.white,
                      backgroundColor: Colors.purple.shade600,
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildWelcomeSection(),
                                  const SizedBox(height: 24),
                                  _buildBalanceOverview(balance, income, expense),
                                  const SizedBox(height: 24),
                                  _buildQuickInsights(income, expense),
                                  const SizedBox(height: 24),
                                  _buildQuickActions(),
                                  const SizedBox(height: 32),
                                  _buildSectionHeader("Recent Activity", Icons.history, "${getRecentTransactions().length} transactions"),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                          if (transactions.isEmpty)
                            SliverFillRemaining(
                              child: _buildEmptyState(),
                            )
                          else
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                  final recentTransactions = getRecentTransactions();
                                  if (index < recentTransactions.length) {
                                    return _buildTransactionCard(recentTransactions[index], index);
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Loading your dashboard...",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No data to display",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Start adding transactions to see\nyour financial insights",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedAppBar() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                "Dashboard",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.red, size: 24),
                onPressed: () => _showLogoutDialog(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Good ${_getTimeOfDay()},",
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${currentUser.displayName ?? 'User'}!",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Here's your financial overview",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
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

  Widget _buildBalanceOverview(double balance, double income, double expense) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.25),
              Colors.white.withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Total Balance",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: balance >= 0 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
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
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                "\$${balance.toStringAsFixed(2)}",
                key: ValueKey(balance),
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildBalanceItem("Income", income, Colors.green, Icons.arrow_downward),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(
                  child: _buildBalanceItem("Expenses", expense, Colors.red, Icons.arrow_upward),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(String title, double amount, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            "\$${amount.toStringAsFixed(2)}",
            key: ValueKey(amount),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickInsights(double income, double expense) {
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
                  child: _buildInsightCard(
                    "Savings Rate",
                    "${savingsRate.toStringAsFixed(1)}%",
                    Icons.savings_outlined,
                    savingsRate >= 20 ? Colors.green : savingsRate >= 10 ? Colors.orange : Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInsightCard(
                    "Spending",
                    spendingTrend,
                    Icons.trending_up_outlined,
                    spendingTrend == "Low" ? Colors.green : spendingTrend == "Moderate" ? Colors.orange : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInsightCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
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
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quick Actions",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  "Add Transaction",
                  Icons.add_circle_outline,
                  Colors.blue,
                      () => _navigateToAddTransaction(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  "View All",
                  Icons.list_alt_outlined,
                  Colors.purple,
                      () => Navigator.push(
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
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.3),
                color.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction, int index) {
    return AnimatedBuilder(
      animation: _statsAnimation,
      builder: (context, child) {
        final delay = index * 0.1;
        final animationValue = (_statsAnimation.value - delay).clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(0, 30 * (1 - animationValue)),
          child: Opacity(
            opacity: animationValue,
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {}, // Add navigation if needed
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (transaction.type == "income" ? Colors.green : Colors.red)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            transaction.type == "income" ? Icons.arrow_downward : Icons.arrow_upward,
                            color: transaction.type == "income" ? Colors.green : Colors.red,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                transaction.date.toLocal().toString().split(' ')[0],
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "\$${transaction.amount.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: transaction.type == "income" ? Colors.green : Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to sign out?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeScreen())
                );
              },
              child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
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