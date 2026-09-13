import 'dart:async';
import 'dart:developer';

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
  String userName = '';

  HomeCubit() : super(HomeInitial()) {
    loadAll();
  }

  List<TransactionModel> transactions = [];
  double totalBalance = 0;
  bool isLoading = true;
  bool showAllTransactions = false;

  // ─── FAMILY SYNC (LIVE LISTENER) ─────────────────────────────────────────
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _familyTxSub;
  Set<String> _knownCloudIds =
      {}; // cloud ids we've seen (safe to delete locally if they vanish)

  Future<String> _getFamilyId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final fid = snap.data()?['familyId'];
    return (fid == null || fid.toString().isEmpty) ? user.uid : fid.toString();
  }

  Future<String> _myName() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('user_name') ?? '';
    if (saved.isNotEmpty) return saved;
    return user?.displayName ?? user?.email ?? '';
  }

  void _upsertLocalState(TransactionModel tx) {
    final i = transactions.indexWhere((t) => t.id == tx.id);
    if (i != -1) {
      transactions[i] = tx;
    } else {
      transactions.insert(0, tx);
    }
  }

  /// Live listener: remote adds/updates/deletes from family members
  /// flow into local DB + state automatically.
  Future<void> _startFamilyListener() async {
    await _familyTxSub?.cancel();
    final familyId = await _getFamilyId();
    if (familyId.isEmpty) return;

    _familyTxSub = FirebaseFirestore.instance
        .collection('families')
        .doc(familyId)
        .collection('transactions')
        .snapshots()
        .listen((snapshot) async {
          try {
            final cloudIds = <String>{};
            for (final doc in snapshot.docs) {
              cloudIds.add(doc.id);
              final id = int.tryParse(doc.id);
              if (id == null) continue;
              final tx = TransactionModel.fromMap(doc.data())..id = id;
              await dbService.addTransaction(
                tx,
              ); // INSERT OR REPLACE → id preserved
              _upsertLocalState(tx);
            }
            // Deleted on another device → remove locally.
            // Only ids we know came from cloud are touched, so offline-only
            // local rows are never deleted by the listener.
            for (final gone in _knownCloudIds.difference(cloudIds)) {
              final id = int.tryParse(gone);
              if (id != null) {
                await dbService.deleteTransaction(id);
                transactions.removeWhere((t) => t.id == id);
              }
            }
            _knownCloudIds = cloudIds;
            emit(HomeLoaded(transactions, totalBalance));
          } catch (e) {
            log('❌ Family listener error: $e');
          }
        });
  }

  /// Re-syncs from scratch and (re)starts the live listener.
  /// Call this after joining/leaving a family or toggling the sync setting.
  Future<void> restartFamilySync() async {
    final prefs = await SharedPreferences.getInstance();
    final syncing = prefs.getBool('is_syncing') ?? false;
    if (syncing && await _hasInternet()) {
      await _syncFromFirestore();
      await _startFamilyListener();
    } else {
      await _familyTxSub?.cancel();
      _familyTxSub = null;
    }
  }

  @override
  Future<void> close() {
    _familyTxSub?.cancel();
    return super.close();
  }

  // ─── CONNECTIVITY CHECK ────────────────────────────────────────────────────

  Future<bool> _hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // ─── LOAD ALL ──────────────────────────────────────────────────────────────
  // Entry point. If online + sync enabled → two-way Firestore sync first,
  // then start the live listener, then load local DB into state.
  // If offline → load from local DB only (works without internet).

  Future<void> loadAll() async {
    if (state is! HomeLoaded) emit(HomeLoading());
    try {
      final online = await _hasInternet();

      final prefs = await SharedPreferences.getInstance();
      final bool isSyncing = prefs.getBool('is_syncing') ?? false;
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && online && isSyncing) {
        await _syncFromFirestore();
        await _startFamilyListener();
      }

      await _loadFromLocal();
    } catch (e) {
      emit(HomeError('Failed to load data: $e'));
    }
  }

  // ─── REFRESH ───────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    // force re-sync on manual pull
    await loadAll();
  }

  // ─── LOCAL-FIRST ADD (NO BLOCKING) ────────────────────────────────────────

  Future<void> addTransactionLocal(TransactionModel tx) async {
    try {
      if (tx.createdBy == null || tx.createdBy!.isEmpty) {
        tx = tx.copyWith(createdBy: await _myName());
      }

      final int localId = await dbService.addTransaction(tx);
      tx.id = localId;

      transactions.insert(0, tx);

      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getDouble('total_balance') ?? 0;
      final double delta = tx.type == TransactionType.expense
          ? -tx.amount
          : tx.amount;
      final newBalance = current + delta;

      await prefs.setDouble('total_balance', newBalance);
      await prefs.setInt('last_sync', DateTime.now().millisecondsSinceEpoch);

      totalBalance = newBalance;
      emit(HomeLoaded(transactions, totalBalance));

      // Upload to the family cloud too (fire-and-forget)
      syncSingleTransactionToCloud(tx);

      log('✅ Transaction added locally (ID: $localId)');
    } catch (e) {
      log('❌ Failed to add transaction locally: $e');
      emit(HomeError('Failed to add transaction: $e'));
    }
  }

  // ─── LOCAL-FIRST UPDATE (NO BLOCKING) ─────────────────────────────────────

  Future<void> updateTransactionLocal(TransactionModel tx) async {
    try {
      if (tx.id == null) return;

      final oldTx = transactions.firstWhere((t) => t.id == tx.id);
      if (tx.createdBy == null || tx.createdBy!.isEmpty) {
        tx = tx.copyWith(createdBy: oldTx.createdBy ?? await _myName());
      }

      final oldDelta = oldTx.type == TransactionType.expense
          ? oldTx.amount
          : -oldTx.amount;
      final newDelta = tx.type == TransactionType.expense
          ? -tx.amount
          : tx.amount;
      final netChange = newDelta + oldDelta;

      await dbService.updateTransaction(tx);

      final index = transactions.indexWhere((t) => t.id == tx.id);
      if (index != -1) transactions[index] = tx;

      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getDouble('total_balance') ?? 0;
      final newBalance = current + netChange;

      await prefs.setDouble('total_balance', newBalance);
      await prefs.setInt('last_sync', DateTime.now().millisecondsSinceEpoch);

      totalBalance = newBalance;
      emit(HomeLoaded(transactions, totalBalance));

      // Propagate the update to the family cloud
      syncSingleTransactionToCloud(tx);

      log('✅ Transaction updated locally (ID: ${tx.id})');
    } catch (e) {
      log('❌ Failed to update transaction locally: $e');
      emit(HomeError('Failed to update transaction: $e'));
    }
  }

  // ─── BACKGROUND SYNC (FIRE-AND-FORGET) ───────────────────────────────────

  void syncSingleTransactionToCloud(TransactionModel tx) {
    Future.microtask(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final bool isSyncing = prefs.getBool('is_syncing') ?? false;
        if (!isSyncing) {
          log('ℹ️ Skipping background tx upload because sync is OFF');
          return;
        }

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;
        if (!await _hasInternet()) return;

        if (tx.createdBy == null || tx.createdBy!.isEmpty) {
          tx = tx.copyWith(createdBy: await _myName());
        }

        final familyId = await _getFamilyId();

        final familyDocRef = FirebaseFirestore.instance
            .collection('families')
            .doc(familyId);
        final txDocRef = familyDocRef
            .collection('transactions')
            .doc(tx.id.toString());
        await txDocRef
            .set(tx.toMap(), SetOptions(merge: true))
            .timeout(const Duration(seconds: 10));

        await familyDocRef
            .set({
              'lastSync': Timestamp.fromDate(DateTime.now()),
              'totalBalance': totalBalance,
            }, SetOptions(merge: true))
            .timeout(const Duration(seconds: 10));

        await prefs.setInt('last_sync', DateTime.now().millisecondsSinceEpoch);

        log('✅ Background tx sync completed (ID: ${tx.id})');
      } catch (e) {
        log('⚠️ Background sync failed (will retry later): $e');
      }
    });
  }

  // ─── TWO-WAY SYNC: FIRESTORE ↔ LOCAL DB ───────────────────────────────────
  // - Uploads local rows missing from cloud (offline leftovers), ids preserved
  // - Pulls cloud rows into local via upsert (INSERT OR REPLACE, no duplicates,
  //   no id renumbering)
  // - Removes local rows whose cloud id vanished (deleted on another device)

  Future<void> _syncFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      log('⚠️ No logged-in user, skipping Firebase sync');
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final familyId = await _getFamilyId();
      if (familyId.isEmpty) return;
      final familyDocRef = firestore.collection('families').doc(familyId);

      // 1. Sync balance from Firestore
      final familyDoc = await familyDocRef.get();
      if (familyDoc.exists) {
        final data = familyDoc.data()!;
        final cloudLastTimestamp =
            (data['lastSync'] as Timestamp?)?.toDate().millisecondsSinceEpoch ??
            0;
        final prefs = await SharedPreferences.getInstance();
        final localLast = prefs.getInt('last_sync') ?? 0;

        if (cloudLastTimestamp > localLast) {
          final cloudBalance = (data['totalBalance'] ?? 0).toDouble();
          await prefs.setDouble('total_balance', cloudBalance);
          totalBalance = cloudBalance;
          log('✅ Balance synced from Firestore: $cloudBalance (cloud newer)');
        } else {
          log('ℹ️ Skipping cloud balance (local changes newer)');
        }
      }

      // 2. Two-way transaction sync
      final snapshot = await familyDocRef.collection('transactions').get();
      final cloudMap = {for (final d in snapshot.docs) d.id: d.data()};

      // 2a. Upload local rows missing from cloud (offline leftovers)
      for (final tx in await dbService.getTransactions()) {
        if (tx.id == null) continue;
        final key = tx.id.toString();
        if (!cloudMap.containsKey(key)) {
          await familyDocRef
              .collection('transactions')
              .doc(key)
              .set(tx.toMap(), SetOptions(merge: true));
        }
      }

      // 2b. Pull cloud rows into local (upsert, id preserved)
      final cloudIds = cloudMap.keys.toSet();
      for (final entry in cloudMap.entries) {
        final id = int.tryParse(entry.key);
        if (id == null) continue;
        final tx = TransactionModel.fromMap(entry.value)..id = id;
        await dbService.addTransaction(tx);
        _upsertLocalState(tx);
      }

      // 2c. Rows that were on cloud but vanished = deleted on another device
      for (final gone in _knownCloudIds.difference(cloudIds)) {
        final id = int.tryParse(gone);
        if (id != null) {
          await dbService.deleteTransaction(id);
          transactions.removeWhere((t) => t.id == id);
        }
      }
      _knownCloudIds = cloudIds;

      log('✅ Two-way sync done: ${cloudMap.length} cloud transactions');
    } catch (e) {
      // Don't crash the app if sync fails — fall back to local data
      log('❌ Firebase sync failed: $e');
    }
  }

  // ─── LOAD FROM LOCAL DB → STATE ────────────────────────────────────────────

  Future<void> _loadFromLocal() async {
    final loadedTransactions = await dbService.getTransactions();
    final prefs = await SharedPreferences.getInstance();
    totalBalance = prefs.getDouble('total_balance') ?? 0;
    transactions = loadedTransactions;
    emit(HomeLoaded(transactions, totalBalance));
  }

  // ─── DELETE (LOCAL + CLOUD) ────────────────────────────────────────────────

  Future<void> removeTransaction(TransactionModel tx) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getDouble('total_balance') ?? 0;
      final delta = tx.type == TransactionType.expense ? -tx.amount : tx.amount;
      totalBalance = current - delta;
      await prefs.setDouble('total_balance', totalBalance);

      transactions.removeWhere((t) => t.id == tx.id);

      if (tx.id != null) {
        await dbService.deleteTransaction(tx.id!);
        await deleteTransactionFromFireBase(tx.id.toString());
      }

      emit(HomeLoaded(transactions, totalBalance));
    } catch (e) {
      log('❌ Failed to delete transaction: $e');
    }
  }

  // ─── DELETE FROM FIREBASE ──────────────────────────────────────────────────

  Future<void> deleteTransactionFromFireBase(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final familyId = await _getFamilyId();

      await FirebaseFirestore.instance
          .collection('families')
          .doc(familyId)
          .collection('transactions')
          .doc(id)
          .delete();
      log('✅ تم الحذف من Firestore');
    } catch (e) {
      log('❌ فشل الحذف من Firestore: $e');
    }
  }

  // ─── KEPT FOR BACKWARDS COMPATIBILITY ──────────────────────────────────────

  Future<void> fetchDataFromFireBase() async {
    await loadAll();
  }

  // ─── CATEGORY LABELS ───────────────────────────────────────────────────────

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

  // ─── LOAD TRANSACTIONS (used after add/edit) ───────────────────────────────

  Future<void> loadTransactions() async {
    try {
      final data = await dbService.getTransactions();
      transactions = data;
      emit(HomeLoaded(transactions, totalBalance));
    } catch (e) {
      emit(HomeError('Failed to load transactions: $e'));
    }
  }

  // ─── LOAD BALANCE ───────────────────────────────────────────────────────────

  Future<void> loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      totalBalance = prefs.getDouble('total_balance') ?? 0;
      emit(HomeLoaded(transactions, totalBalance));
    } catch (e) {
      emit(HomeError('Failed to load balance: $e'));
    }
  }

  // ─── SET BALANCE ────────────────────────────────────────────────────────────

  Future<void> setBalance(double value) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setDouble('total_balance', value);
      totalBalance = value;

      // Persist balance to Firestore families collection
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final online = await _hasInternet();
        if (online) {
          final familyId = await _getFamilyId();

          await FirebaseFirestore.instance
              .collection('families')
              .doc(familyId)
              .set({
                'totalBalance': value,
                'lastSync': Timestamp.fromDate(DateTime.now()),
              }, SetOptions(merge: true));
          log('✅ Balance saved to Firestore: $value');
        }
      }

      emit(HomeLoaded(transactions, totalBalance));
    } catch (e) {
      emit(HomeError('Failed to set balance: $e'));
    }
  }

  // ─── HELPERS ────────────────────────────────────────────────────────────────

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
      .fold(0, (sum, t) => sum + t.amount);

  double get totalExpenses => transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  double get netChange => totalIncome - totalExpenses;

  double get spentRatio {
    final availableFunds =
        totalExpenses + totalBalance.clamp(0, double.infinity);
    if (availableFunds <= 0) return 0;
    return (totalExpenses / availableFunds).clamp(0, 1.0);
  }

  double get percentChange {
    return spentRatio * 100;
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
        .fold(0, (sum, t) => sum + t.amount);
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

  Future<void> addTransaction(TransactionModel tx) async {
    try {
      if (tx.createdBy == null || tx.createdBy!.isEmpty) {
        tx = tx.copyWith(createdBy: await _myName());
      }

      final int localId = await dbService.addTransaction(tx);
      tx.id = localId;
      transactions.insert(0, tx);

      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getDouble('total_balance') ?? 0;
      final double delta = tx.type == TransactionType.expense
          ? -tx.amount
          : tx.amount;
      final newBalance = current + delta;
      await prefs.setDouble('total_balance', newBalance);

      // mark local change time so cloud won't overwrite if cloud sync tries to pull
      await prefs.setInt('last_sync', DateTime.now().millisecondsSinceEpoch);

      totalBalance = newBalance;
      emit(HomeLoaded(transactions, totalBalance));

      // Only attempt immediate cloud upload if sync is enabled
      final bool isSyncing = prefs.getBool('is_syncing') ?? false;
      final user = FirebaseAuth.instance.currentUser;
      if (isSyncing && user != null && await _hasInternet()) {
        // upload this single transaction in background
        syncSingleTransactionToCloud(tx);
      }
    } catch (e) {
      emit(HomeError('Failed to add transaction: $e'));
    }
  }

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedUserName = prefs.getString('user_name') ?? '';
      userName = savedUserName;

      // Reload home state with any changed settings
      emit(HomeLoaded(transactions, totalBalance));
    } catch (e) {
      emit(HomeError('Failed to load settings: $e'));
    }
  }
}
