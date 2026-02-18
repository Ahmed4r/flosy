import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/home/data/model/transaction_model.dart';
import 'package:flosy/features/home/presentation/cubit/home_cubit.dart';
import 'package:flosy/features/home/presentation/screens/add_transaction_screen.dart';
import 'package:flosy/features/home/presentation/screens/recording_screen.dart';
import 'package:flosy/features/home/presentation/widgets/build_amount_card.dart';
import 'package:flosy/features/home/presentation/widgets/build_header.dart';
import 'package:flosy/features/home/presentation/widgets/build_tracks.dart';
import 'package:flosy/features/settings/cubit/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flosy/features/home/presentation/services/db.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TransactionColors {
  food(Colors.orange),
  rent(Colors.blue),
  transport(Colors.green),
  shopping(Colors.purple),
  fun(Colors.red),
  health(Colors.teal),
  salary(Colors.indigo),
  more(Colors.grey);

  final Color color;
  const TransactionColors(this.color);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  Future<void> refresh() async {
    // Call your cubit's refresh method here
    context.read<HomeCubit>().refresh();
  }

  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().loadAll();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = AppTheme.isDarkMode(context);
    bool isArabic = context.read<HomeCubit>().isArabicLocale(context);

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return _buildLoadingShimmer(isDarkMode);
        }
        if (state is HomeError) {
          return Center(child: Text(state.message));
        }
        final getGreetingMessage = context.read<HomeCubit>().getGreetingMessage;
        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => context.read<HomeCubit>().refresh(),
              color: AppColors.greenColor,
              displacement: 40,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8.h),
                    buildHeader(context, getGreetingMessage),
                    SizedBox(height: 20.h),
                    buildAmountCard(
                      context,
                      _buildPercentageChip,
                      context.read<HomeCubit>().totalBalance,
                      _showEditBalanceDialog,
                      context.read<HomeCubit>().percentChange / 100,
                      isDarkMode,
                      isArabic,
                    ),
                    SizedBox(height: 20.h),
                    buildTracks(
                      context,
                      context.read<HomeCubit>().totalIncome,
                      context.read<HomeCubit>().totalExpenses,
                    ),
                    SizedBox(height: 16.h),
                    _buildRecentTransactions(isDarkMode),
                    SizedBox(height: 100.h),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── PERCENTAGE CHIP ─────────────────────────────────

  Widget _buildPercentageChip() {
    final pct = context.read<HomeCubit>().percentChange;
    final isPositive = context.read<HomeCubit>().netChange >= 0;
    final color = isPositive ? AppColors.greenColor : Colors.redAccent;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 14.sp,
            color: color,
          ),
          SizedBox(width: 4.w),
          Text(
            '${pct.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─── LOADING SHIMMER ─────────────────────────────────

  Widget _buildLoadingShimmer(bool isDarkMode) {
    final shimmerColor = isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
    final baseColor = isDarkMode ? Colors.grey[900]! : Colors.grey[100]!;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          // Header shimmer
          Row(
            children: [
              CircleAvatar(radius: 22.r, backgroundColor: shimmerColor),
              SizedBox(width: 14.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    width: 120.w,
                    height: 16.h,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20.h),
          // Balance card shimmer
          Container(
            width: double.infinity,
            height: 150.h,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(24.r),
            ),
          ),
          SizedBox(height: 16.h),
          // Track cards shimmer
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 110.h,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Container(
                  height: 110.h,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Chart shimmer
          Container(
            width: double.infinity,
            height: 200.h,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),
          SizedBox(height: 20.h),
          // Transaction shimmer
          ...List.generate(
            3,
            (i) => Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Container(
                height: 70.h,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── RECENT TRANSACTIONS ─────────────────────────────

  Widget _buildRecentTransactions(bool isDarkMode) {
    final displayTransactions = context.read<HomeCubit>().showAllTransactions
        ? context.read<HomeCubit>().transactions
        : context.read<HomeCubit>().transactions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'home.recent_transactions'.tr(),
              style: AppText.body18(context).copyWith(
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            if (context.read<HomeCubit>().transactions.length > 5)
              GestureDetector(
                onTap: () =>
                    context.read<HomeCubit>().showAllTransactionsToggle(),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    context.read<HomeCubit>().showAllTransactions
                        ? 'Show Less'
                        : 'See All',
                    style: AppText.body12(context).copyWith(
                      color: AppColors.greenColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 14.h),

        // Transactions grouped by day
        if (context.read<HomeCubit>().transactions.isEmpty)
          _buildEmptyTransactions(isDarkMode)
        else
          _buildGroupedTransactions(displayTransactions, isDarkMode),
      ],
    );
  }

  Widget _buildEmptyTransactions(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40.h),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64.w,
            height: 64.h,
            decoration: BoxDecoration(
              color: AppColors.greenColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 30.sp,
              color: AppColors.greenColor,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'home.no_transactions'.tr(),
            style: AppText.body16(context).copyWith(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Tap + to add your first transaction',
            style: AppText.body12(context).copyWith(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedTransactions(
    List<TransactionModel> transactions,
    bool isDarkMode,
  ) {
    // Group by date label
    final Map<String, List<TransactionModel>> grouped = {};
    for (final tx in transactions) {
      final label = context.read<HomeCubit>().getDateLabel(tx.date);
      grouped.putIfAbsent(label, () => []).add(tx);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date label
            Padding(
              padding: EdgeInsets.only(bottom: 8.h, left: 4.w),
              child: Text(
                entry.key,
                style: AppText.body12(context).copyWith(
                  color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            // Transaction items
            ...entry.value.map((tx) => _buildTransactionTile(tx, isDarkMode)),
            SizedBox(height: 12.h),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTransactionTile(TransactionModel transaction, bool isDarkMode) {
    final isExpense = transaction.type == TransactionType.expense;
    final catColor = TransactionColors.values
        .firstWhere(
          (c) => c.name == transaction.category,
          orElse: () => TransactionColors.more,
        )
        .color;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return Dismissible(
            key: ValueKey(transaction.id ?? transaction.hashCode),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 24.w),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 24.sp,
              ),
            ),
            onDismissed: (_) async {
              try {
                final prefs = await SharedPreferences.getInstance();
                double current = prefs.getDouble('total_balance') ?? 0.0;
                final delta = transaction.amount * (isExpense ? -1.0 : 1.0);
                current -= delta;
                await prefs.setDouble('total_balance', current);
                if (!mounted) return;
                final idx = context.read<HomeCubit>().transactions.indexOf(
                  transaction,
                );
                setState(() {
                  context.read<HomeCubit>().totalBalance = current;
                  if (idx >= 0)
                    context.read<HomeCubit>().transactions.removeAt(idx);
                });
                if (transaction.id != null) {
                  await dbService.deleteTransaction(transaction.id!);

                  await context.read<HomeCubit>().deleteTransactionFromFireBase(
                    transaction.id.toString(),
                  );
                }
              } catch (e) {
                log('Failed to delete transaction: $e');
              }
            },
            child: GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AddTransactionScreen(transaction: transaction),
                  ),
                );
                if (result == true) {
                  if (!mounted) return;
                  await context.read<HomeCubit>().loadTransactions();
                  if (!mounted) return;
                  await context.read<HomeCubit>().loadBalance();
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkMode ? 0.15 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Category icon
                    Container(
                      width: 46.w,
                      height: 46.h,
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(
                        transaction.icon,
                        color: catColor,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 14.w),

                    // Title & category
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.title,
                            style: AppText.body16(context).copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            context.read<HomeCubit>().getCategoryLabel(
                              transaction.category,
                            ),
                            style: AppText.body12(context).copyWith(
                              color: isDarkMode
                                  ? Colors.grey[500]
                                  : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Amount
                    BlocBuilder<SettingsCubit, SettingsState>(
                      bloc: context.read<SettingsCubit>(),
                      builder: (context, state) {
                        String currency = 'EGP';
                        if (state is SettingsLoaded) {
                          currency = state.selectedCurrency;
                        }
                        return Text(
                          context.read<HomeCubit>().isArabicLocale(context)
                              ? '${transaction.amount.toStringAsFixed(1)}${currency}${isExpense ? '-' : '+'}'
                              : '${isExpense ? '-' : '+'}\$${transaction.amount.toStringAsFixed(2)}',
                          style: AppText.body16(context).copyWith(
                            color: isExpense
                                ? Colors.redAccent
                                : AppColors.greenColor,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── EDIT BALANCE DIALOG ─────────────────────────────

  Future<void> _showEditBalanceDialog() async {
    bool isDarkMode = AppTheme.isDarkMode(context);
    final controller = TextEditingController(
      text: context.read<HomeCubit>().totalBalance.toStringAsFixed(1),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Text(
            'Set total balance'.tr(),
            style: AppText.body18(context).copyWith(
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppText.body16(
              context,
            ).copyWith(color: isDarkMode ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: '0.0',
              hintStyle: TextStyle(color: Colors.grey[500]),
              filled: true,
              fillColor: isDarkMode ? Colors.grey[850] : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'cancel'.tr(),
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
            TextButton(
              onPressed: () {
                final value = double.tryParse(controller.text);
                if (value == null) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('transaction.invalid_amount'.tr()),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, value);
              },
              child: Text(
                'save'.tr(),
                style: TextStyle(
                  color: AppColors.greenColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (result != null) {
      if (!mounted) return;
      await context.read<HomeCubit>().setBalance(result);
    }
  }
}
