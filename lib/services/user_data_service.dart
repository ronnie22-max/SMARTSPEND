import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartspend/models/transaction_model.dart';

/// Single Firestore structure per user:
///
///   users/{uid}/
///     data (document)
///       cashBalance: double
///       budget: { Food: double, ... }
///     transactions (subcollection)
///       {txnId} (document)  ← one doc per TransactionRecord
class UserDataService {
  static final UserDataService _instance = UserDataService._internal();
  factory UserDataService() => _instance;
  UserDataService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>? get _dataDoc {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('data').doc('main');
  }

  CollectionReference<Map<String, dynamic>>? get _txnCol {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('transactions');
  }

  // ─── Cash Balance ───────────────────────────────────────────────────────────

  Future<void> saveCashBalance(double balance) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _dataDoc?.set({
        'cashBalance': balance,
        'cashUpdatedAtMs': now,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('UserDataService: saveCashBalance error: $e');
    }
  }

  Future<Map<String, dynamic>?> loadCashBalanceData() async {
    try {
      final snap = await _dataDoc?.get();
      if (snap == null || !snap.exists) return null;
      final data = snap.data();
      if (data == null || data['cashBalance'] == null) return null;
      return {
        'cashBalance': (data['cashBalance'] as num).toDouble(),
        'cashUpdatedAtMs': (data['cashUpdatedAtMs'] as num?)?.toInt() ?? 0,
      };
    } catch (e) {
      debugPrint('UserDataService: loadCashBalanceData error: $e');
      return null;
    }
  }

  Future<double?> loadCashBalance() async {
    try {
      final data = await loadCashBalanceData();
      return (data?['cashBalance'] as num?)?.toDouble();
    } catch (e) {
      debugPrint('UserDataService: loadCashBalance error: $e');
      return null;
    }
  }

  // ─── Budget ─────────────────────────────────────────────────────────────────

  Future<void> saveBudget(Map<String, double> budget) async {
    try {
      await _dataDoc?.set({'budget': budget}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('UserDataService: saveBudget error: $e');
    }
  }

  Future<Map<String, double>?> loadBudget() async {
    try {
      final snap = await _dataDoc?.get();
      if (snap == null || !snap.exists) return null;
      final raw = snap.data()?['budget'];
      if (raw == null) return null;
      return Map<String, double>.fromEntries(
        (raw as Map<String, dynamic>).entries.map(
          (e) => MapEntry(e.key, (e.value as num).toDouble()),
        ),
      );
    } catch (e) {
      debugPrint('UserDataService: loadBudget error: $e');
      return null;
    }
  }

  // ─── Transactions ────────────────────────────────────────────────────────────

  Future<void> saveTransaction(TransactionRecord txn) async {
    try {
      await _txnCol?.doc(txn.id).set(txn.toJson());
    } catch (e) {
      debugPrint('UserDataService: saveTransaction error: $e');
    }
  }

  Future<void> deleteTransaction(String txnId) async {
    try {
      await _txnCol?.doc(txnId).delete();
    } catch (e) {
      debugPrint('UserDataService: deleteTransaction error: $e');
    }
  }

  Future<void> deleteAllTransactions() async {
    try {
      final col = _txnCol;
      if (col == null) return;
      final snap = await col.get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('UserDataService: deleteAllTransactions error: $e');
    }
  }

  Future<List<TransactionRecord>> loadTransactions() async {
    try {
      final col = _txnCol;
      if (col == null) return [];
      final snap = await col.orderBy('timestamp', descending: true).get();
      return snap.docs
          .map((doc) => TransactionRecord.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('UserDataService: loadTransactions error: $e');
      return [];
    }
  }
}
