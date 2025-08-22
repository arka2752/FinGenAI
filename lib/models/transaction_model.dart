import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  String id;
  String title;
  double amount;
  String category;
  DateTime date;
  String type; // "income" or "expense"
  String? notes; // optional notes field

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.type,
    this.notes, // optional
  });

  /// Convert model to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date), // Firestore-friendly timestamp
      'type': type,
      if (notes != null) 'notes': notes, // only include if not null
    };
  }

  /// Create model from a Map (e.g., Firestore document)
  factory TransactionModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return TransactionModel(
      id: docId ?? map['id'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] ?? '',
      date: (map['date'] is Timestamp)
          ? (map['date'] as Timestamp).toDate()
          : DateTime.parse(map['date']),
      type: map['type'] ?? 'expense',
      notes: map['notes'], // safely handle optional notes
    );
  }

  /// Create model from Firestore DocumentSnapshot
  factory TransactionModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      title: data['title'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      category: data['category'] ?? '',
      date: (data['date'] is Timestamp)
          ? (data['date'] as Timestamp).toDate()
          : DateTime.parse(data['date']),
      type: data['type'] ?? 'expense',
      notes: data['notes'], // safely handle optional notes
    );
  }
}
