import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class TransactionService {
  CollectionReference _userTransactions(String userId) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('transactions');

  Future<void> addTransaction(TransactionModel transaction, String userId) async {
    try {
      await _userTransactions(userId).doc(transaction.id).set({
        ...transaction.toMap(),
        'date': Timestamp.fromDate(transaction.date),
      });
      print("Transaction added successfully");
    } catch (e) {
      print("Error adding transaction: $e");
      rethrow;
    }
  }

  Future<void> updateTransaction(TransactionModel transaction, String userId) async {
    try {
      await _userTransactions(userId).doc(transaction.id).update({
        ...transaction.toMap(),
        'date': Timestamp.fromDate(transaction.date),
      });
      print("Transaction updated successfully");
    } catch (e) {
      print("Error updating transaction: $e");
      rethrow;
    }
  }

  Future<void> deleteTransaction(String transactionId, String userId) async {
    try {
      await _userTransactions(userId).doc(transactionId).delete();
      print("Transaction deleted successfully");
    } catch (e) {
      print("Error deleting transaction: $e");
      rethrow;
    }
  }

  Stream<List<TransactionModel>> getUserTransactions(String userId) {
    return _userTransactions(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => TransactionModel.fromDoc(doc)).toList());
  }

  /// Fetch transactions once
  Future<List<TransactionModel>> getUserTransactionsOnce(String userId) async {
    try {
      final snapshot = await _userTransactions(userId)
          .orderBy('date', descending: true)
          .get();
      return snapshot.docs.map((doc) => TransactionModel.fromDoc(doc)).toList();
    } catch (e) {
      print("Error fetching transactions: $e");
      rethrow;
    }
  }

  /// -------------------- ANALYTICS METHODS --------------------

  /// Aggregate expenses by category
  Future<Map<String, double>> getExpensesByCategory(String userId) async {
    final transactions = await getUserTransactionsOnce(userId);
    final Map<String, double> data = {};

    for (var tx in transactions) {
      if (tx.type == 'expense') {
        data[tx.category] = (data[tx.category] ?? 0) + tx.amount;
      }
    }
    return data;
  }

  /// Aggregate income and expenses by month (YYYY-MM)
  Future<Map<String, Map<String, double>>> getMonthlyIncomeExpense(String userId) async {
    final transactions = await getUserTransactionsOnce(userId);
    final Map<String, Map<String, double>> monthlyData = {};

    for (var tx in transactions) {
      final monthKey =
          "${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}";
      monthlyData[monthKey] ??= {'income': 0, 'expense': 0};

      monthlyData[monthKey]![tx.type] =
          (monthlyData[monthKey]![tx.type] ?? 0) + tx.amount;
    }
    return monthlyData;
  }

  /// Total balance (income - expenses)
  Future<double> getTotalBalance(String userId) async {
    final transactions = await getUserTransactionsOnce(userId);
    double balance = 0;
    for (var tx in transactions) {
      if (tx.type == 'income') {
        balance += tx.amount;
      } else {
        balance -= tx.amount;
      }
    }
    return balance;
  }
}
