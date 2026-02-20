import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flosy/features/home/data/model/transaction_model.dart';
import 'package:flosy/features/home/presentation/services/db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());
  List<TransactionModel> transactions = [];
  double totalBalance = 0.0;
  bool isLoading = true;
  bool showAllTransactions = false;

  // ─── CONNECTIVITY CHECK ──────────────────────────────────────────────────────

  Future<bool> _hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // ─── LOAD ALL ────────────────────────────────────────────────────────────────
  // Entry point called from HomeScreen.initState().
  // If online → sync from Firestore first, then load from local DB.
  // If offline → load from local DB only (works without internet).

  bool _hasSyncedThisSession = false;

  Future<void> loadAll() async {
    if (state is! HomeLoaded) {
      emit(HomeLoading());
    }
    try {
      final online = await _hasInternet();
      // Only sync from Firebase once per session
      if (online && !_hasSyncedThisSession) {
        await _syncFromFirestore();
        _hasSyncedThisSession = true;
      }
      await _loadFromLocal();
    } catch (e) {
      emit(HomeError('Failed to load data: $e'));
    }
  }

  // ─── REFRESH ─────────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    _hasSyncedThisSession = false; // force re-sync on manual pull
    await loadAll();
  }

  // ─── SYNC FROM FIRESTORE → LOCAL DB ─────────────────────────────────────────
  // Pulls all transactions + balance from Firestore and overwrites local DB.
  // Uses the Firestore doc ID as the source of truth to avoid duplicates.

  Future<void> _syncFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      log('⚠️ No logged-in user, skipping Firebase sync');
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final userDocRef = firestore.collection('users').doc(user.uid);

      // 1. Sync balance from Firestore
      final userDoc = await userDocRef.get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final cloudLastTimestamp =
            (data['lastSync'] as Timestamp?)?.toDate().millisecondsSinceEpoch ??
            0;
        final prefs = await SharedPreferences.getInstance();
        final localLast = prefs.getInt('last_sync') ?? 0;

        if (cloudLastTimestamp > localLast) {
          final cloudBalance = (data['totalBalance'] ?? 0.0).toDouble();
          await prefs.setDouble('total_balance', cloudBalance);
          totalBalance = cloudBalance;
          log('✅ Balance synced from Firestore: $cloudBalance (cloud newer)');
        } else {
          log('ℹ️ Skipping cloud balance (local changes newer)');
        }
      }

      // 2. Sync transactions from Firestore
      final snapshot = await userDocRef.collection('transactions').get();
      if (snapshot.docs.isEmpty) {
        log('ℹ️ No transactions found in Firestore');
        return;
      }

      final cloudTransactions = snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data()))
          .toList();

      // Clear local DB and replace with cloud data (avoids duplicates completely)
      await dbService.deleteAllTransactions();
      for (final tx in cloudTransactions) {
        await dbService.addTransaction(tx);
      }

      log('✅ Synced ${cloudTransactions.length} transactions from Firestore');
    } catch (e) {
      // Don't crash the app if sync fails — fall back to local data
      log('❌ Firebase sync failed: $e');
    }
  }

  // ─── LOAD FROM LOCAL DB → STATE ──────────────────────────────────────────────

  Future<void> _loadFromLocal() async {
    final loadedTransactions = await dbService.getTransactions();
    final prefs = await SharedPreferences.getInstance();
    totalBalance = prefs.getDouble('total_balance') ?? 0.0;
    transactions = loadedTransactions;
    emit(HomeLoaded(transactions, totalBalance));
  }

  // ─── DELETE FROM FIREBASE ────────────────────────────────────────────────────

  Future<void> deleteTransactionFromFireBase(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(id)
          .delete();
      log('✅ تم الحذف من Firestore');
    } catch (e) {
      log('❌ فشل الحذف من Firestore: $e');
    }
  }

  // ─── KEPT FOR BACKWARDS COMPATIBILITY ────────────────────────────────────────
  // (was called manually before — now loadAll() handles this automatically)

  Future<void> fetchDataFromFireBase() async {
    await loadAll();
  }

  // ─── CATEGORY LABELS ─────────────────────────────────────────────────────────

  String getCategoryLabel(String id) {
    switch (id) {
      case 'food':
        return 'categories.food'.tr();
      case 'rent':
        return 'categories.rent'.tr();
      case 'transport':
        return 'categories.transport'.tr();
      case 'shopping':
        return 'categories.shopping'.tr();
      case 'fun':
        return 'categories.fun'.tr();
      case 'health':
        return 'categories.health'.tr();
      case 'salary':
        return 'categories.salary'.tr();
      case 'more':
        return 'categories.more'.tr();
      default:
        return id;
    }
  }

  // ─── LOAD TRANSACTIONS (used after add/edit) ──────────────────────────────────

  Future<void> loadTransactions() async {
    try {
      final data = await dbService.getTransactions();
      transactions = data;
      emit(HomeLoaded(transactions, totalBalance));
    } catch (e) {
      emit(HomeError('Failed to load transactions: $e'));
    }
  }

  // ─── LOAD BALANCE ─────────────────────────────────────────────────────────────

  Future<void> loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      totalBalance = prefs.getDouble('total_balance') ?? 0.0;
      emit(HomeLoaded(transactions, totalBalance));
    } catch (e) {
      emit(HomeError('Failed to load balance: $e'));
    }
  }

  // ─── SET BALANCE ──────────────────────────────────────────────────────────────

  Future<void> setBalance(double value) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setDouble('total_balance', value);
      totalBalance = value;

      // Also persist balance to Firestore so other devices get it too
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final online = await _hasInternet();
        if (online) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({'totalBalance': value}, SetOptions(merge: true));
          log('✅ Balance saved to Firestore: $value');
        }
      }

      emit(HomeLoaded(transactions, totalBalance));
    } catch (e) {
      emit(HomeError('Failed to set balance: $e'));
    }
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────────

  bool isArabicLocale(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ar';
  }

  String getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'home.greeting_morning'.tr();
    if (hour < 17) return 'home.greeting_afternoon'.tr();
    return 'home.greeting_evening'.tr();
  }

  double get totalIncome => transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpenses => transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get netChange => totalIncome - totalExpenses;

  double get percentChange {
    final startingBalance = totalBalance + totalExpenses - totalIncome;
    if (startingBalance <= 0) return 0;
    return ((totalExpenses / startingBalance) * 100).clamp(0, 999);
  }

  double get monthlyExpenses {
    final now = DateTime.now();
    return transactions
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              t.date.year == now.year &&
              t.date.month == now.month,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<String, double> get expensesByCategoryAndPercentages {
    final now = DateTime.now();
    final Map<String, double> categoryMap = {};
    for (var t in transactions) {
      if (t.type == TransactionType.expense &&
          t.date.year == now.year &&
          t.date.month == now.month) {
        categoryMap[t.category] = (categoryMap[t.category] ?? 0) + t.amount;
      }
    }
    return categoryMap;
  }

  String getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDay = DateTime(date.year, date.month, date.day);

    if (txDay == today) return 'today'.tr();
    if (txDay == today.subtract(const Duration(days: 1))) {
      return 'yesterday'.tr();
    }
    if (now.difference(txDay).inDays < 7) {
      String weekdayKey =
          'home.${DateFormat('EEEE').format(date).toLowerCase()}';
      return weekdayKey.tr();
    }
    return DateFormat('MMM d, yyyy').format(date);
  }

  Future<void> showAllTransactionsToggle() async {
    showAllTransactions = !showAllTransactions;
    emit(HomeLoaded(transactions, totalBalance));
  }
}
