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
    // Subscribe to real-time transactions
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
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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
      // Pass the latest transactions and session context to AI service
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
    return Scaffold(
      appBar: AppBar(title: const Text("AI Transaction Chat")),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment:
                  msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 14),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: msg.isUser ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: Radius.circular(msg.isUser ? 12 : 0),
                        bottomRight: Radius.circular(msg.isUser ? 0 : 12),
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: msg.isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Input box
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: "Type a message (e.g., add 50 USD)",
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isProcessing
                      ? const CircularProgressIndicator()
                      : IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _sendMessage(_controller.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
