import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum TransactionType { income, expense, deposit, withdrawal, budgetSpend }

class TransactionRecord {
  final String id;
  final String title;
  final String category;
  final IconData icon;
  final DateTime timestamp;
  final double amount;
  final TransactionType type;
  final String? description;
  final double? budgetRemaining;

  TransactionRecord({
    required this.id,
    required this.title,
    required this.category,
    required this.icon,
    required this.timestamp,
    required this.amount,
    required this.type,
    this.description,
    this.budgetRemaining,
  });

  String get formattedTime =>
      "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}";

  String get formattedDate =>
      "${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}";

  Color get typeColor {
    switch (type) {
      case TransactionType.income:
      case TransactionType.deposit:
        return Colors.green;
      case TransactionType.expense:
      case TransactionType.withdrawal:
      case TransactionType.budgetSpend:
        return Colors.red;
    }
  }

  String get typeLabel {
    switch (type) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.deposit:
        return 'Deposit';
      case TransactionType.withdrawal:
        return 'Withdrawal';
      case TransactionType.budgetSpend:
        return 'Budget Spend';
    }
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'iconCodePoint': icon.codePoint,
      'timestamp': timestamp.toIso8601String(),
      'amount': amount,
      'type': type.toString().split('.').last,
      'description': description,
      'budgetRemaining': budgetRemaining,
    };
  }

  // Create from JSON
  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    return TransactionRecord(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      icon: IconData(json['iconCodePoint'], fontFamily: 'MaterialIcons'),
      timestamp: DateTime.parse(json['timestamp']),
      amount: json['amount'].toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      description: json['description'],
      budgetRemaining: json['budgetRemaining']?.toDouble(),
    );
  }
}

class TransactionManager {
  static final TransactionManager _instance = TransactionManager._internal();

  factory TransactionManager() {
    return _instance;
  }

  TransactionManager._internal();

  final List<TransactionRecord> _transactions = [];
  static const String _storageKey = 'smartspend_transactions';

  List<TransactionRecord> get transactions => List.unmodifiable(_transactions);

  void addTransaction(TransactionRecord transaction) {
    _transactions.insert(0, transaction);
    saveTransactions();
  }

  void removeTransaction(String transactionId) {
    _transactions.removeWhere((txn) => txn.id == transactionId);
    saveTransactions();
  }

  Map<String, List<TransactionRecord>> getTransactionsByDate() {
    final Map<String, List<TransactionRecord>> grouped = {};
    for (var txn in _transactions) {
      grouped.putIfAbsent(txn.formattedDate, () => []).add(txn);
    }
    return grouped;
  }

  List<TransactionRecord> getTransactionsByType(TransactionType type) {
    return _transactions.where((txn) => txn.type == type).toList();
  }

  double getTotalByType(TransactionType type) {
    return _transactions
        .where((txn) => txn.type == type)
        .fold(0, (sum, txn) => sum + txn.amount);
  }

  void clearTransactions() {
    _transactions.clear();
    saveTransactions();
  }

  // Save transactions to SharedPreferences
  Future<void> saveTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _transactions.map((txn) => jsonEncode(txn.toJson())).toList();
      await prefs.setStringList(_storageKey, jsonList);
    } catch (e) {
      debugPrint('Error saving transactions: $e');
    }
  }

  // Load transactions from SharedPreferences
  Future<void> loadTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey) ?? [];
      final loaded = jsonList
          .map((jsonStr) => TransactionRecord.fromJson(jsonDecode(jsonStr)))
          .toList();
      _transactions
        ..clear()
        ..addAll(loaded);
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    }
  }
}
