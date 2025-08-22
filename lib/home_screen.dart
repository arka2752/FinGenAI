import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import 'dashboard_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/ai_transaction_service.dart';
import 'transaction_screen.dart';
import 'analytics_screen.dart';
import 'analytics_screen_v2.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser!;
  bool _isButtonHovered = false;

  final AITransactionService _aiService = AITransactionService();

  Map<String, dynamic> _sessionContext = {};


  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _rotationController;
  late AnimationController _balanceController;
  late AnimationController _cardStaggerController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _balanceAnimation;
  late Animation<double> _cardStaggerAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 12));
    _balanceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _cardStaggerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.8), end: Offset.zero).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(_rotationController);
    _balanceAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _balanceController, curve: Curves.easeOutBack));
    _cardStaggerAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _cardStaggerController, curve: Curves.easeOutCubic));
  }

  void _startAnimations() async {
    _rotationController.repeat();
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _scaleController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();
    _balanceController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _cardStaggerController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _rotationController.dispose();
    _balanceController.dispose();
    _cardStaggerController.dispose();
    super.dispose();
  }

  double calculateBalance(List<TransactionModel> transactions) {
    double balance = 0;
    for (var tx in transactions) {
      balance += (tx.type == "income" ? tx.amount : -tx.amount);
    }
    return balance;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;
    final isLargeScreen = size.height > 900;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primaryContainer,
              colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildMaterialAppBar(colorScheme, isSmallScreen),
              SizedBox(height: isSmallScreen ? 16 : 24),
              Expanded(
                child: StreamBuilder<List<TransactionModel>>(
                  stream: TransactionService().getUserTransactions(currentUser.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildMaterialLoadingState(colorScheme);
                    }

                    final transactions = snapshot.data ?? [];
                    final balance = calculateBalance(transactions);

                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(() {});
                      },
                      color: colorScheme.primary,
                      backgroundColor: colorScheme.surface,
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Column(
                              children: [
                                _buildMaterialBalanceCard(balance, colorScheme, isSmallScreen),
                                SizedBox(height: isSmallScreen ? 20 : 32),
                                _buildMaterialQuickStats(transactions, colorScheme, isSmallScreen),
                                SizedBox(height: isSmallScreen ? 20 : 24),
                                _buildMaterialActionButtons(colorScheme, isSmallScreen),
                                SizedBox(height: isSmallScreen ? 20 : 32),
                                if (transactions.isNotEmpty)
                                  _buildMaterialSectionHeader(transactions, colorScheme, isSmallScreen),
                                SizedBox(height: isSmallScreen ? 12 : 16),
                              ],
                            ),
                          ),
                          if (transactions.isEmpty)
                            SliverFillRemaining(
                              child: _buildMaterialEmptyState(colorScheme, isSmallScreen),
                            )
                          else
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                    (context, index) => _buildMaterialTransactionCard(
                                      transactions[index], 
                                      index, 
                                      colorScheme, 
                                      isSmallScreen
                                    ),
                                childCount: transactions.length,
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

  Widget _buildMaterialAppBar(ColorScheme colorScheme, bool isSmallScreen) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          isSmallScreen ? 16 : 20, 
          isSmallScreen ? 16 : 20, 
          isSmallScreen ? 16 : 20, 
          isSmallScreen ? 8 : 10
        ),
        child: Column(
          children: [
            Row(
              children: [
                Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                  color: colorScheme.surface,
                  child: Container(
                    padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.1),
                        width: 1,
                      ),
                  ),
                  child: RotationTransition(
                    turns: _rotationAnimation,
                      child: Icon(
                        Icons.account_balance_wallet, 
                        color: colorScheme.primary, 
                        size: isSmallScreen ? 24 : 28
                  ),
                ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "FinGenAI",
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        "Welcome back, ${currentUser.displayName ?? 'User'}!",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildMaterialIconButton(
                  colorScheme,
                  Icons.person_outlined,
                  () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
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
                      );
                    },
                  isSmallScreen,
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                _buildMaterialIconButton(
                  colorScheme,
                  Icons.notifications_outlined,
                  () {},
                  isSmallScreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialIconButton(ColorScheme colorScheme, IconData icon, VoidCallback onPressed, bool isSmallScreen) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
      color: colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: IconButton(
          icon: Icon(icon, color: colorScheme.primary, size: isSmallScreen ? 20 : 24),
          onPressed: onPressed,
          constraints: BoxConstraints(
            minWidth: isSmallScreen ? 40 : 48,
            minHeight: isSmallScreen ? 40 : 48,
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialBalanceCard(double balance, ColorScheme colorScheme, bool isSmallScreen) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _balanceAnimation,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
          child: Material(
            elevation: 16,
            borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
            color: colorScheme.surface,
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
          decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                      Text(
                    "Total Balance",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                        padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                    decoration: BoxDecoration(
                          color: (balance >= 0 ? Colors.green : Colors.red).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                    ),
                    child: Icon(
                      balance >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: balance >= 0 ? Colors.green : Colors.red,
                          size: isSmallScreen ? 14 : 16,
                    ),
                  ),
                ],
              ),
                  SizedBox(height: isSmallScreen ? 8 : 12),
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
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialQuickStats(List<TransactionModel> transactions, ColorScheme colorScheme, bool isSmallScreen) {
    final income = transactions
        .where((tx) => tx.type == "income")
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final expenses = transactions
        .where((tx) => tx.type == "expense")
        .fold(0.0, (sum, tx) => sum + tx.amount);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
        child: Row(
          children: [
            Expanded(
              child: _buildMaterialStatCard("Income", income, Icons.arrow_downward, Colors.green, colorScheme, isSmallScreen),
            ),
            SizedBox(width: isSmallScreen ? 12 : 16),
            Expanded(
              child: _buildMaterialStatCard("Expenses", expenses, Icons.arrow_upward, Colors.red, colorScheme, isSmallScreen),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialStatCard(String title, double amount, IconData icon, Color color, ColorScheme colorScheme, bool isSmallScreen) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
      color: colorScheme.surface,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
      ),
      child: Column(
        children: [
          Row(
            children: [
                Icon(icon, color: color, size: isSmallScreen ? 18 : 20),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Expanded(
                  child: Text(
                title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
            SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            "\$${amount.toStringAsFixed(2)}",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildMaterialActionButtons(ColorScheme colorScheme, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMaterialInteractiveButton(colorScheme, isSmallScreen)),
              SizedBox(width: isSmallScreen ? 12 : 16),
              _buildMaterialMicButton(colorScheme, isSmallScreen),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          SizedBox(
            width: double.infinity,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
              color: colorScheme.primary,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnalyticsScreenV2(userId: currentUser.uid),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                  ),
                ),
                child: Text(
                  "View Analytics",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialInteractiveButton(ColorScheme colorScheme, bool isSmallScreen) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isButtonHovered = true),
        onExit: (_) => setState(() => _isButtonHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()
            ..scale(_isButtonHovered ? 1.05 : 1.0)
            ..rotateZ(_isButtonHovered ? 0.02 : 0.0),
          child: Material(
            elevation: _isButtonHovered ? 12 : 8,
            borderRadius: BorderRadius.circular(isSmallScreen ? 25 : 30),
            color: colorScheme.primary,
            child: InkWell(
              borderRadius: BorderRadius.circular(isSmallScreen ? 25 : 30),
              onTap: () => showAddTransactionSheet(context),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 24 : 32, 
                  vertical: isSmallScreen ? 16 : 20
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 3 : 4),
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                      ),
                      child: Icon(
                        Icons.add, 
                        color: colorScheme.onPrimary, 
                        size: isSmallScreen ? 18 : 20
                    ),
                    ),
                    SizedBox(width: isSmallScreen ? 10 : 12),
                    Text(
                      "Add Transaction",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
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
  }

  Widget _buildMaterialMicButton(ColorScheme colorScheme, bool isSmallScreen) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(isSmallScreen ? 25 : 30),
      color: colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isSmallScreen ? 25 : 30),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: IconButton(
          icon: Icon(
            Icons.smart_toy, 
            color: colorScheme.primary, 
            size: isSmallScreen ? 28 : 32
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TransactionChatScreen(),
              ),
            );
          },
          constraints: BoxConstraints(
            minWidth: isSmallScreen ? 50 : 60,
            minHeight: isSmallScreen ? 50 : 60,
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialSectionHeader(List<TransactionModel> transactions, ColorScheme colorScheme, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
      child: Row(
        children: [
          Icon(
            Icons.history, 
            color: colorScheme.onSurface.withOpacity(0.7), 
            size: isSmallScreen ? 18 : 20
          ),
          SizedBox(width: isSmallScreen ? 6 : 8),
          Text(
            "Recent Transactions",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Text(
            "${transactions.length} items",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialTransactionCard(TransactionModel transaction, int index, ColorScheme colorScheme, bool isSmallScreen) {
    return AnimatedBuilder(
      animation: _cardStaggerAnimation,
      builder: (context, child) {
        final delay = index * 0.1;
        final animationValue = (_cardStaggerAnimation.value - delay).clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(0, 50 * (1 - animationValue)),
          child: Opacity(
            opacity: animationValue,
            child: Container(
              margin: EdgeInsets.fromLTRB(
                isSmallScreen ? 16 : 20, 
                8, 
                isSmallScreen ? 16 : 20, 
                8
              ),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                color: colorScheme.surface,
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                    onTap: () {},
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                            decoration: BoxDecoration(
                              color: (transaction.type == "income" ? Colors.green : Colors.red)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                            ),
                            child: Icon(
                              transaction.type == "income" ? Icons.arrow_downward : Icons.arrow_upward,
                              color: transaction.type == "income" ? Colors.green : Colors.red,
                              size: isSmallScreen ? 18 : 20,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 12 : 16),
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
                                SizedBox(height: isSmallScreen ? 3 : 4),
                                Text(
                                  transaction.date.toLocal().toString().split(' ')[0],
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "\$${transaction.amount.toStringAsFixed(2)}",
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: transaction.type == "income" ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 6 : 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildMaterialActionIcon(
                                    colorScheme,
                                    Icons.edit_outlined,
                                    () => showEditTransactionSheet(context, transaction),
                                    isSmallScreen,
                                  ),
                                  SizedBox(width: isSmallScreen ? 6 : 8),
                                  _buildMaterialActionIcon(
                                    colorScheme,
                                    Icons.delete_outline,
                                    () => _showDeleteConfirmation(context, transaction),
                                    isSmallScreen,
                                    isDestructive: true,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildMaterialActionIcon(ColorScheme colorScheme, IconData icon, VoidCallback onPressed, bool isSmallScreen, {bool isDestructive = false}) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
      color: isDestructive ? Colors.red.withOpacity(0.1) : colorScheme.surfaceVariant.withOpacity(0.5),
      child: InkWell(
        borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
          child: Icon(
            icon, 
            color: isDestructive ? Colors.red : colorScheme.primary, 
            size: isSmallScreen ? 16 : 18
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: colorScheme.surface,
            child: Container(
              padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: CircularProgressIndicator(
                color: colorScheme.primary,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Loading your transactions...",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
                          ),
                        ],
                      ),
    );
  }

  Widget _buildMaterialEmptyState(ColorScheme colorScheme, bool isSmallScreen) {
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
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: isSmallScreen ? 56 : 64,
                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
            ),
          SizedBox(height: isSmallScreen ? 20 : 24),
          Text(
            "No transactions yet",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 32 : 40),
            child: Text(
              "Start tracking your finances by adding\nyour first transaction",
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

  void showAICommandSheet(BuildContext context, List<TransactionModel> transactions) {
    final commandController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;
    final isSmallScreen = MediaQuery.of(context).size.height < 700;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(isSmallScreen ? 24 : 28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: isSmallScreen ? 20 : 24),
                decoration: BoxDecoration(
                  color: colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
                alignment: Alignment.center,
              ),
              Text(
                "AI Command",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallScreen ? 20 : 24),
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                child: TextField(
                  controller: commandController,
                  decoration: InputDecoration(
                    labelText: "Enter command",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12)),
                    prefixIcon: Icon(Icons.mic, color: colorScheme.primary),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 20 : 24),
              Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                color: colorScheme.primary,
                child: ElevatedButton(
              onPressed: () async {
                    final command = commandController.text.trim();
                    if (command.isEmpty) return;

                    Navigator.pop(context); // close sheet
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Processing command..."),
                        backgroundColor: colorScheme.primary,
                      ),
                    );

                    final response = await _aiService.handleCommand(
                      command,
                      FirebaseAuth.instance.currentUser!.uid,
                      transactions,
                      _sessionContext, // added 4th parameter
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(response),
                        backgroundColor: colorScheme.secondary,
                      ),
                    );

                    setState(() {}); // Refresh UI after command
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12)),
                  ),
                  child: Text(
                    "Send",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 16),
            ],
          ),
        ),
      ),
    );
  }


  /// Calls Gemini API and executes commands
  Future<String> _processAICommand(String command) async {
    const apiKey = "YOUR_GEMINI_API_KEY"; // Replace with your key
    const url = "https://api.openrouter.ai/v1/chat/completions"; // Gemini endpoint

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "gemini-1.1",
        "messages": [
          {"role": "user", "content": command}
        ]
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("AI API Error: ${response.body}");
    }

    final data = jsonDecode(response.body);
    final aiMessage = data['choices'][0]['message']['content'];

    // Parse AI response for basic commands
    final lower = aiMessage.toLowerCase();

    if (lower.contains("add transaction")) {
      // Expect format: "add transaction title=Lunch amount=12.5 type=expense"
      final titleMatch = RegExp(r"title=([^\s]+)").firstMatch(lower);
      final amountMatch = RegExp(r"amount=([\d.]+)").firstMatch(lower);
      final typeMatch = RegExp(r"type=(income|expense)").firstMatch(lower);

      if (titleMatch != null && amountMatch != null && typeMatch != null) {
        final transaction = TransactionModel(
          id: const Uuid().v4(),
          title: titleMatch.group(1)!,
          amount: double.parse(amountMatch.group(1)!),
          type: typeMatch.group(1)!,
          category: typeMatch.group(1)!, // simple mapping
          date: DateTime.now(),
        );
        await TransactionService().addTransaction(transaction, FirebaseAuth.instance.currentUser!.uid);
        return "Transaction '${transaction.title}' added successfully!";
      } else {
        return "Failed to parse transaction. Please specify title, amount, and type.";
      }
    } else if (lower.contains("delete transaction")) {
      // Expect format: "delete transaction <title>"
      final titleMatch = RegExp(r"delete transaction (.+)").firstMatch(lower);
      if (titleMatch != null) {
        final title = titleMatch.group(1)!;
        final transactions = await TransactionService().getUserTransactionsOnce(FirebaseAuth.instance.currentUser!.uid);
        final toDelete = transactions.firstWhere(
              (tx) => tx.title.toLowerCase() == title.toLowerCase(),
          orElse: () => throw Exception('Transaction not found'), // Or handle differently
        );

        if (toDelete != null) {
          await TransactionService().deleteTransaction(toDelete.id, FirebaseAuth.instance.currentUser!.uid);
          return "Transaction '$title' deleted successfully!";
        } else {
          return "Transaction '$title' not found!";
        }
      }
    } else if (lower.contains("show balance")) {
      final transactions = await TransactionService().getUserTransactionsOnce(FirebaseAuth.instance.currentUser!.uid);
      final balance = transactions.fold<double>(0, (sum, tx) => sum + (tx.type == "income" ? tx.amount : -tx.amount));
      return "Your current balance is \$${balance.toStringAsFixed(2)}";
    }

    return aiMessage; // fallback: just return AI's text
  }

  void showAddTransactionSheet(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String category = "Income";
    final colorScheme = Theme.of(context).colorScheme;
    final isSmallScreen = MediaQuery.of(context).size.height < 700;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(isSmallScreen ? 24 : 28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: isSmallScreen ? 20 : 24),
                decoration: BoxDecoration(
                  color: colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
                alignment: Alignment.center,
              ),
              Text(
                "Add Transaction",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallScreen ? 20 : 24),
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                child: TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: "Title",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12)),
                    prefixIcon: Icon(Icons.title, color: colorScheme.primary),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 16),
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                child: TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Amount",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12)),
                    prefixIcon: Icon(Icons.attach_money, color: colorScheme.primary),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 16),
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                child: DropdownButtonFormField<String>(
                value: category,
                decoration: InputDecoration(
                  labelText: "Category",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12)),
                    prefixIcon: Icon(Icons.category, color: colorScheme.primary),
                    filled: true,
                    fillColor: colorScheme.surface,
                ),
                items: ["Income", "Expense"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) category = value;
                },
              ),
              ),
              SizedBox(height: isSmallScreen ? 20 : 24),
              Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                color: colorScheme.primary,
                child: ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty || amountController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Please fill all fields"),
                          backgroundColor: colorScheme.error,
                        ),
                    );
                    return;
                  }

                  final transaction = TransactionModel(
                    id: const Uuid().v4(),
                    title: titleController.text,
                    amount: double.parse(amountController.text),
                    category: category,
                    date: DateTime.now(),
                    type: category.toLowerCase(),
                  );

                  try {
                    await TransactionService().addTransaction(transaction, currentUser.uid);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Transaction added successfully"),
                          backgroundColor: colorScheme.primary,
                        ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Failed to add transaction: $e"),
                            backgroundColor: colorScheme.error,
                          ));
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12)),
                  ),
                  child: Text(
                    "Add Transaction", 
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 16),
            ],
          ),
        ),
      ),
    );
  }

  void showEditTransactionSheet(BuildContext context, TransactionModel transaction) {
    final titleController = TextEditingController(text: transaction.title);
    final amountController = TextEditingController(text: transaction.amount.toString());
    String category = transaction.type == "income" ? "Income" : "Expense";
    final colorScheme = Theme.of(context).colorScheme;
    final isSmallScreen = MediaQuery.of(context).size.height < 700;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(isSmallScreen ? 24 : 28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: isSmallScreen ? 20 : 24),
                decoration: BoxDecoration(
                  color: colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
                alignment: Alignment.center,
              ),
              Text(
                "Edit Transaction",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallScreen ? 20 : 24),
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                child: TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: "Title",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12)),
                    prefixIcon: Icon(Icons.title, color: colorScheme.primary),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 16),
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                child: TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Amount",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12)),
                    prefixIcon: Icon(Icons.attach_money, color: colorScheme.primary),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 16),
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                child: DropdownButtonFormField<String>(
                value: category,
                decoration: InputDecoration(
                  labelText: "Category",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12)),
                    prefixIcon: Icon(Icons.category, color: colorScheme.primary),
                    filled: true,
                    fillColor: colorScheme.surface,
                ),
                items: ["Income", "Expense"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) category = value;
                },
              ),
              ),
              SizedBox(height: isSmallScreen ? 20 : 24),
              Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                color: colorScheme.primary,
                child: ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty || amountController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Please fill all fields"),
                          backgroundColor: colorScheme.error,
                        ),
                    );
                    return;
                  }

                  final updatedTransaction = TransactionModel(
                    id: transaction.id,
                    title: titleController.text,
                    amount: double.parse(amountController.text),
                    category: category,
                    date: transaction.date, // Keep original date
                    type: category.toLowerCase(),
                  );

                  try {
                    await TransactionService().updateTransaction(updatedTransaction, currentUser.uid);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Transaction updated successfully"),
                          backgroundColor: colorScheme.primary,
                        ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Failed to update transaction: $e"),
                            backgroundColor: colorScheme.error,
                          ));
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12)),
                  ),
                  child: Text(
                    "Update Transaction", 
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 16),
            ],
          ),
        ),
      ),
    );
  }
  void _showDeleteConfirmation(BuildContext context, TransactionModel transaction) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSmallScreen = MediaQuery.of(context).size.height < 700;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          elevation: 24,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
          ),
          title: Text(
            'Delete Transaction',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${transaction.title}"?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
            Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              color: colorScheme.error,
              child: TextButton(
                onPressed: () async {
                  await TransactionService().deleteTransaction(transaction.id, currentUser.uid);
                  Navigator.pop(context);
                },
                child: Text(
                  'Delete',
                  style: TextStyle(color: colorScheme.onError),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}