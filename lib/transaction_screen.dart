import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../services/ai_transaction_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class TransactionChatScreen extends StatefulWidget {
  const TransactionChatScreen({super.key});

  @override
  _TransactionChatScreenState createState() => _TransactionChatScreenState();
}

class _TransactionChatScreenState extends State<TransactionChatScreen> {
  final transactionService = TransactionService();
  final aiTransactionService = AITransactionService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isProcessing = false;

  List<TransactionModel> _transactions = [];
  StreamSubscription<List<TransactionModel>>? _transactionSubscription;
  Map<String, dynamic> _sessionContext = {}; // session context for multi-step AI

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser!;
    _transactionSubscription = transactionService
        .getUserTransactions(currentUser.uid)
        .listen((transactions) {
      _transactions = transactions;
    });
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent, // reverse:true
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser!;
    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: true));
      _isProcessing = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final reply = await aiTransactionService.handleCommand(
        text,
        currentUser.uid,
        _transactions,
        _sessionContext,
      );

      setState(() {
        _messages.insert(0, ChatMessage(text: reply, isUser: false));
        _isProcessing = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.insert(
            0,
            ChatMessage(
                text: "Something went wrong. Please try again.",
                isUser: false));
        _isProcessing = false;
      });
      _scrollToBottom();
      print("Error in AI command: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 600;
    final isExtraSmallScreen = size.height < 500;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildMaterialAppBar(colorScheme, isSmallScreen, isExtraSmallScreen),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyChatState(colorScheme, isSmallScreen, isExtraSmallScreen)
                : _buildChatMessages(colorScheme, isSmallScreen, isExtraSmallScreen),
          ),
          _buildMaterialInputBox(colorScheme, isSmallScreen, isExtraSmallScreen),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildMaterialAppBar(ColorScheme colorScheme, bool isSmallScreen, bool isExtraSmallScreen) {
    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 4,
      shadowColor: colorScheme.shadow.withOpacity(0.3),
      title: Text(
        "AI Transaction Chat",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.info_outline, color: colorScheme.primary),
          onPressed: () => _showHelpDialog(context),
        ),
      ],
    );
  }

  Widget _buildEmptyChatState(ColorScheme colorScheme, bool isSmallScreen, bool isExtraSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 50, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            "Start a conversation",
            style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            "Type your first message below",
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages(ColorScheme colorScheme, bool isSmallScreen, bool isExtraSmallScreen) {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.all(12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _buildMaterialMessageBubble(msg, colorScheme);
      },
    );
  }

  Widget _buildMaterialMessageBubble(ChatMessage msg, ColorScheme colorScheme) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
        decoration: BoxDecoration(
          color: msg.isUser ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: msg.isUser
              ? [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  msg.isUser ? Icons.person : Icons.smart_toy,
                  size: 16,
                  color: msg.isUser ? colorScheme.onPrimary : colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  msg.isUser ? "You" : "AI Assistant",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: msg.isUser ? colorScheme.onPrimary : colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              msg.text,
              style: TextStyle(
                color: msg.isUser ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialInputBox(ColorScheme colorScheme, bool isSmallScreen, bool isExtraSmallScreen) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: "Ask about finances...",
                  filled: true,
                  fillColor: colorScheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  prefixIcon: Icon(Icons.chat_bubble_outline, color: colorScheme.primary),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
            const SizedBox(width: 6),
            _isProcessing
                ? Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 2),
              ),
            )
                : IconButton(
              icon: Icon(Icons.send, color: colorScheme.primary),
              onPressed: () => _sendMessage(_controller.text),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("AI Assistant Help", style: TextStyle(color: colorScheme.onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem("Add Transaction", "add 50 USD for lunch", Icons.add, colorScheme),
              _buildHelpItem("View Balance", "show my balance", Icons.account_balance_wallet, colorScheme),
              _buildHelpItem("Analyze Spending", "analyze my expenses", Icons.analytics, colorScheme),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Got it!", style: TextStyle(color: colorScheme.primary)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpItem(String title, String example, IconData icon, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
              Text(example, style: TextStyle(color: colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
            ],
          )
        ],
      ),
    );
  }
}
