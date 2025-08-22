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


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser!;
  bool _isButtonHovered = false;

  // final aiService = AITransactionService(); // AI Service instance
  final AITransactionService _aiService = AITransactionService();

  Map<String, dynamic> _sessionContext = {}; // session context for AI commands


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
              const SizedBox(height: 24),
              Expanded(
                child: StreamBuilder<List<TransactionModel>>(
                  stream: TransactionService().getUserTransactions(currentUser.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingState();
                    }

                    final transactions = snapshot.data ?? [];
                    final balance = calculateBalance(transactions);

                    return RefreshIndicator(
                      onRefresh: () async {
                        // Trigger rebuild
                        setState(() {});
                      },
                      color: Colors.white,
                      backgroundColor: Colors.purple.shade600,
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Column(
                              children: [
                                _buildBalanceCard(balance),
                                const SizedBox(height: 32),
                                _buildQuickStats(transactions),
                                const SizedBox(height: 24),
                                // Row with Add Transaction button + AI mic
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(child: _buildInteractiveButton()),
                                          const SizedBox(width: 16),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.mic, color: Colors.white, size: 32),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => TransactionChatScreen(),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => AnalyticsScreen(userId: currentUser.uid),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.purple.shade600,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text(
                                            "View Analytics",
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 32),
                                if (transactions.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.history, color: Colors.white70, size: 20),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "Recent Transactions",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          "${transactions.length} items",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white60,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                          if (transactions.isEmpty)
                            SliverFillRemaining(
                              child: _buildEmptyState(),
                            )
                          else
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                    (context, index) => _buildTransactionCard(transactions[index], index),
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


  void showAICommandSheet(BuildContext context, List<TransactionModel> transactions) {
    final commandController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
                alignment: Alignment.center,
              ),
              const Text(
                "AI Command",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: commandController,
                decoration: InputDecoration(
                  labelText: "Enter command",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.mic),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final command = commandController.text.trim();
                  if (command.isEmpty) return;

                  Navigator.pop(context); // close sheet
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Processing command...")),
                  );

                  final response = await _aiService.handleCommand(
                    command,
                    FirebaseAuth.instance.currentUser!.uid,
                    transactions,
                    _sessionContext, // added 4th parameter
                  );


                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(response)),
                  );

                  setState(() {}); // Refresh UI after command
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Send", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
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


  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Loading your transactions...",
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
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No transactions yet",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Start tracking your finances by adding\nyour first transaction",
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
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: RotationTransition(
                    turns: _rotationAnimation,
                    child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "FinGenAI",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        "Welcome back, ${currentUser.displayName ?? 'User'}!",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.dashboard_outlined, color: Colors.white, size: 24),
                    onPressed: () {
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
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _balanceAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
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
            border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                  const Text(
                    "Total Balance",
                    style: TextStyle(
                      fontSize: 16,
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
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  "\$${balance.toStringAsFixed(2)}",
                  key: ValueKey(balance),
                  style: TextStyle(
                    fontSize: 36,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(List<TransactionModel> transactions) {
    final income = transactions
        .where((tx) => tx.type == "income")
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final expenses = transactions
        .where((tx) => tx.type == "expense")
        .fold(0.0, (sum, tx) => sum + tx.amount);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard("Income", income, Icons.arrow_downward, Colors.green),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard("Expenses", expenses, Icons.arrow_upward, Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
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
          Text(
            "\$${amount.toStringAsFixed(2)}",
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

  Widget _buildInteractiveButton() {
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: _isButtonHovered
                  ? [Colors.cyan.shade400, Colors.blue.shade500, Colors.purple.shade600]
                  : [Colors.blue.shade600, Colors.purple.shade600, Colors.indigo.shade700],
            ),
            boxShadow: [
              BoxShadow(
                color: _isButtonHovered ? Colors.cyan.withOpacity(0.4) : Colors.purple.withOpacity(0.3),
                blurRadius: _isButtonHovered ? 20 : 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => showAddTransactionSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Add Transaction",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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

  Widget _buildTransactionCard(TransactionModel transaction, int index) {
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
              margin: EdgeInsets.fromLTRB(20, 8, 20, index == 0 ? 8 : 8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {}, // Add tap functionality if needed
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (transaction.type == "income" ? Colors.green : Colors.red)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              transaction.type == "income" ? Icons.arrow_downward : Icons.arrow_upward,
                              color: transaction.type == "income" ? Colors.green : Colors.red,
                              size: 20,
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "\$${transaction.amount.toStringAsFixed(2)}",
                                style: TextStyle(
                                  color: transaction.type == "income" ? Colors.green : Colors.red,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                                      onPressed: () => showEditTransactionSheet(context, transaction),
                                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                      onPressed: () => _showDeleteConfirmation(context, transaction),
                                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                    ),
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
  void _showDeleteConfirmation(BuildContext context, TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Transaction', style: TextStyle(color: Colors.white)),
          content: Text(
            'Are you sure you want to delete "${transaction.title}"?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                await TransactionService().deleteTransaction(transaction.id, currentUser.uid);
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void showAddTransactionSheet(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String category = "Income";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
                alignment: Alignment.center,
              ),
              const Text(
                "Add Transaction",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: "Title",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Amount",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: category,
                decoration: InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: ["Income", "Expense"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) category = value;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty || amountController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")),
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
                      const SnackBar(content: Text("Transaction added successfully")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to add transaction: $e")));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Add Transaction", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
                alignment: Alignment.center,
              ),
              const Text(
                "Edit Transaction",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: "Title",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Amount",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: category,
                decoration: InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: ["Income", "Expense"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) category = value;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty || amountController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")),
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
                      const SnackBar(content: Text("Transaction updated successfully")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to update transaction: $e")));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Update Transaction", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}