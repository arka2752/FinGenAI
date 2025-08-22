import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';
import 'deepseek_service.dart';

class AITransactionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DeepSeekService _deepSeek = DeepSeekService();

  /// System prompt for AI
  final String systemPrompt = """
You are a precise financial tracker chatbot. Your only goal is to help users add income and expenses to their ledger.

**INSTRUCTIONS:**
1. Determine if the user is referring to an expense or income. Look for keywords:
    - Expense: "spent", "paid", "cost", "bought", "expense", "outgoing"
    - Income: "earned", "received", "salary", "income", "invoice", "gift", "deposit"
2. The 'title' should be a short description based on the category.
3. If the user provides amount and category, and type is clear, create transaction for today.
4. If info is missing (category, or type ambiguous), ask a follow-up question. NEVER guess.
5. Always respond in JSON with:
{
  "intent": "add_expense" | "add_income" | "clarify" | "chat",
  "amount": number | null,
  "category": "string" | null,
  "date": "YYYY-MM-DD" | null,
  "message": "String to display"
}
""";

  /// Safely parse amount to double
  double parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Add transaction to Firestore
  Future<void> addTransaction(TransactionModel t, String userId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(t.id)
        .set(t.toMap());
  }

  /// Get all transactions
  Future<List<TransactionModel>> getAllTransactions(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) => TransactionModel.fromDoc(doc)).toList();
  }

  /// Handle user input
  Future<String> handleCommand(
      String input,
      String userId,
      List<TransactionModel> transactions,
      Map<String, dynamic> sessionContext,
      ) async {
    try {
      // Step 1: If awaiting multi-step info, use sessionContext
      if (sessionContext['awaiting'] != null) {
        final field = sessionContext['awaiting'];
        switch (field) {
          case 'amount':
            final amount = parseAmount(input.replaceAll(RegExp(r'[^\d.]'), ''));
            if (amount == 0.0) return "Please provide a valid amount.";
            sessionContext['amount'] = amount;
            if (sessionContext['type'] == null) {
              sessionContext['awaiting'] = 'type';
              return "Is this an income or expense?";
            } else {
              sessionContext['awaiting'] = 'category';
              return "Got it! What category is this for?";
            }
          case 'type':
            final lower = input.toLowerCase();
            if (lower.contains('income')) {
              sessionContext['type'] = 'income';
            } else if (lower.contains('expense')) {
              sessionContext['type'] = 'expense';
            } else {
              return "Please specify if it's 'income' or 'expense'.";
            }
            sessionContext['awaiting'] = 'category';
            return "Got it! What category is this for?";
          case 'category':
            sessionContext['category'] = input.trim().isEmpty ? 'general' : input.trim();
            sessionContext['awaiting'] = 'notes';
            return "Any notes for this transaction? (optional)";
          case 'notes':
            sessionContext['notes'] = input.trim();
            final transaction = TransactionModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: sessionContext['category'] != null
                  ? "${sessionContext['category']} Transaction"
                  : "AI Transaction",
              amount: sessionContext['amount'],
              category: sessionContext['category'],
              date: DateTime.now(),
              type: sessionContext['type'] ?? 'expense',
              notes: sessionContext['notes'].isEmpty ? null : sessionContext['notes'],
            );
            await addTransaction(transaction, userId);
            sessionContext.clear();
            return "✅ Transaction added: \$${transaction.amount.toStringAsFixed(2)} for '${transaction.category}'${transaction.notes != null ? " with note '${transaction.notes}'" : ""}.";
        }
      }

      // Step 2: Send input to DeepSeek AI
      final aiRaw = await _deepSeek.sendPrompt("$systemPrompt\nUser: $input");

      // Step 3: Parse JSON from AI
      Map<String, dynamic> jsonData;
      try {
        jsonData = json.decode(aiRaw);
      } catch (_) {
        return aiRaw; // If not JSON → casual chat
      }

      // Step 4: Handle AI response based on intent
      switch (jsonData['intent']) {
        case 'add_income':
        case 'add_expense':
          final type = jsonData['intent'] == 'add_income' ? 'income' : 'expense';
          final amount = parseAmount(jsonData['amount']);
          final category = jsonData['category'] ?? 'general';
          final notes = jsonData['notes'];

          // If any info missing → start multi-step flow
          if (amount == 0.0 || category.isEmpty || type.isEmpty) {
            sessionContext['awaiting'] = amount == 0.0
                ? 'amount'
                : (category.isEmpty ? 'category' : 'notes');
            sessionContext['amount'] = amount;
            sessionContext['type'] = type;
            sessionContext['category'] = category;
            return jsonData['message'];
          }

          // Add transaction directly
          final transaction = TransactionModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: category != null ? "$category Transaction" : "AI Transaction",
            amount: amount,
            category: category,
            date: jsonData['date'] != null ? DateTime.parse(jsonData['date']) : DateTime.now(),
            type: type,
            notes: notes,
          );
          await addTransaction(transaction, userId);
          return jsonData['message'];

        case 'clarify':
          sessionContext['awaiting'] = jsonData['amount'] == null
              ? 'amount'
              : (jsonData['category'] == null ? 'category' : 'notes');
          sessionContext['amount'] = parseAmount(jsonData['amount']);
          sessionContext['type'] = jsonData['intent'].contains('income') ? 'income' : 'expense';
          sessionContext['category'] = jsonData['category'];
          return jsonData['message'];

        case 'chat':
        default:
          return jsonData['message'];
      }
    } catch (e) {
      return "⚠️ Error: $e";
    }
  }
}
