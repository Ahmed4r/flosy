import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/features/home/data/model/transaction_model.dart';
import 'package:flosy/features/home/presentation/services/db.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());
  List<TransactionModel> transactions = [];
  double totalBalance = 0.0;
  bool isLoading = true;
  bool showAllTransactions = false;

  Future<void> refresh() async {
    await refreshv2();
  }

  Future<void> loadAll() async {
    emit(HomeLoading());
    try {
      final loadedTransactions = await dbService.getTransactions();
      final prefs = await SharedPreferences.getInstance();
      final loadedBalance = prefs.getDouble('total_balance') ?? 0.0;
      // Update cubit fields!
      transactions = loadedTransactions;
      totalBalance = loadedBalance;
      emit(HomeLoaded(loadedTransactions, loadedBalance));
    } catch (e) {
      emit(HomeError('Failed to load data: $e'));
    }
  }

  Future<void> refreshv2() async {
    await loadAll();
  }

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

  Future<void> loadTransactions() async {
    try {
      final data = await dbService.getTransactions();
      transactions = data;
    } catch (e) {
      emit(HomeError('Failed to load transactions: $e'));
    }
  }

  Future<void> loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      totalBalance = prefs.getDouble('total_balance') ?? 0.0;
    } catch (e) {
      emit(HomeError('Failed to load balance: $e'));
    }
  }

  Future<void> setBalance(double value) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setDouble('total_balance', value);
      totalBalance = value;
    } catch (e) {
      emit(HomeError('Failed to set balance: $e'));
    }
  }

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

  // Group transactions by date label
  String getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDay = DateTime(date.year, date.month, date.day);

    if (txDay == today) return 'Today';
    if (txDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (now.difference(txDay).inDays < 7) {
      return DateFormat('EEEE').format(date); // e.g. "Monday"
    }
    return DateFormat('MMM d, yyyy').format(date);
  }
}
