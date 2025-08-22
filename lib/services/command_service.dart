import 'package:your_app_name/models/transaction_model.dart';
import 'package:your_app_name/services/gemini_service.dart';
import 'package:your_app_name/services/ai_transaction_service.dart';
import 'package:your_app_name/services/transaction_service.dart';

class CommandService {
  final GeminiService _geminiService = GeminiService();
  final AITransactionService _aiTransactionService = AITransactionService();
  final TransactionService _transactionService = TransactionService();

  /// Process a natural language command (like "add 50 tk from father")
  Future<void> processCommand(String command, String userId) async {
    TransactionModel? transaction;

    try {
      // 1. Try Gemini AI
      final geminiResponse = await _geminiService.parseTransaction(command);
      if (geminiResponse != null) {
        transaction = geminiResponse;
      }
    } catch (e) {
      print("Gemini failed: $e");
    }

    // 2. If Gemini failed, fall back to rule-based AI parser
    if (transaction == null) {
      transaction = _aiTransactionService.parseCommand(command);
    }

    // 3. If we got a valid transaction, save it
    if (transaction != null) {
      await _transactionService.addTransaction(userId, transaction);
      print("✅ Transaction saved: ${transaction.title} - ${transaction.amount}");
    } else {
      print("⚠️ Could not understand command: $command");
      throw Exception("Could not process command");
    }
  }
}
