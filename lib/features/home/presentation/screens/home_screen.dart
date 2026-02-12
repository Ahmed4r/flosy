import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/home/data/model/transaction_model.dart';
import 'package:flosy/features/home/presentation/screens/add_transaction_screen.dart';
import 'package:flosy/features/home/presentation/widgets/build_amount_card.dart';
import 'package:flosy/features/home/presentation/widgets/build_chart.dart';
import 'package:flosy/features/home/presentation/widgets/build_header.dart';
import 'package:flosy/features/home/presentation/widgets/build_tracks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flosy/features/home/presentation/services/db.dart';
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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Use DB-backed list
  List<TransactionModel> _transactions = [];

  // Persisted total balance
  double _totalBalance = 0.0;

  // Map stored category ids to localized labels
  String _getCategoryLabel(String id) {
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

  @override
  void initState() {
    super.initState();
    _loadBalance();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final data = await dbService.getTransactions();
    setState(() {
      _transactions = data;
    });
  }

  Future<void> _loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalBalance = prefs.getDouble('total_balance') ?? 0.0;
    });
  }

  Future<void> _setBalance(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('total_balance', value);
    setState(() {
      _totalBalance = value;
    });
  }

  bool isArabicLocale(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ar';
  }

  String getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'home.greeting_morning'.tr();
    } else if (hour < 17) {
      return 'home.greeting_afternoon'.tr();
    } else {
      return 'home.greeting_evening'.tr();
    }
  }

  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalExpenses => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  double get _netChange => totalIncome - totalExpenses;

  // percentage of the *starting* balance that has been spent
  double get _percentChange {
    // reconstruct starting balance:
    // start = currentBalance + expenses - income
    final startingBalance = _totalBalance + totalExpenses - totalIncome;
    if (startingBalance <= 0) return 0;
    final pct = (totalExpenses / startingBalance) * 100;
    return pct.clamp(0, 999); // avoid crazy huge values
  }

  double get monthlyExpenses {
    // calculate total expenses for the current month
    final now = DateTime.now();
    final monthlyExpenses = _transactions
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              t.date.year == now.year &&
              t.date.month == now.month,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
    return monthlyExpenses;
  }

  Map<String, double> get expensesByCategoryAndPercentages {
    // calculate expenses by category for the current month
    final now = DateTime.now();
    final Map<String, double> categoryMap = {};
    for (var t in _transactions) {
      if (t.type == TransactionType.expense &&
          t.date.year == now.year &&
          t.date.month == now.month) {
        categoryMap[t.category] = (categoryMap[t.category] ?? 0) + t.amount;
      }
    }
    return categoryMap;
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = AppTheme.isDarkMode(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: isArabicLocale(context)
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                SizedBox(height: 20.h),
                buildHeader(context, getGreetingMessage),
                SizedBox(height: 10.h),
                buildAmountCard(
                  context,
                  buildView,
                  _totalBalance,
                  _showEditBalanceDialog,
                  _percentChange / 100, // <-- pass ratio for progress bar

                  isDarkMode,
                  // <-- pass currency symbol
                ),
                SizedBox(height: 10.h),
                buildTracks(context, totalIncome, totalExpenses),
                SizedBox(height: 10.h),
                buildChart(
                  context,
                  expenses: monthlyExpenses,
                  categories: expensesByCategoryAndPercentages,
                  isArabic: isArabicLocale(context),
                ),
                SizedBox(height: 10.h),
                buildRecentTransactions(isDarkMode),
                SizedBox(height: 90.h), // Bottom padding for nav bar
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditBalanceDialog() async {
    final controller = TextEditingController(
      text: _totalBalance.toStringAsFixed(2),
    );
    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set total balance'.tr()),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(hintText: ''),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () {
                final value = double.tryParse(controller.text);
                if (value == null) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('transaction.invalid_amount'.tr()),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, value);
              },
              child: Text('save'.tr()),
            ),
          ],
        );
      },
    );
    if (result != null) {
      await _setBalance(result);
    }
  }

  Widget buildView() {
    // percentage chip only
    final pct = _percentChange;
    final isPositive = _netChange >= 0; // arrow based on net change
    final arrowIcon = isPositive
        ? FontAwesomeIcons.arrowUp
        : FontAwesomeIcons.arrowDown;
    final color = isPositive ? AppColors.greenColor : Colors.red;
    final pctText = '${pct.toStringAsFixed(1)}%';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: const Color.fromARGB(41, 255, 255, 255),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(arrowIcon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            pctText,
            style: AppText.body12grey(context).copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget buildRecentTransactions(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'home.recent_transactions'.tr(),
          style: AppText.body16(context).copyWith(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        buildTransactionsList(),
      ],
    );
  }

  Widget buildTransactionsList() {
    bool isDarkMode = AppTheme.isDarkMode(context);
    if (_transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32.h),
          child: Column(
            children: [
              Text(
                'home.no_transactions'.tr(),
                style: AppText.body14(context).copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      separatorBuilder: (context, index) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        final isExpense = transaction.type == TransactionType.expense;

        return Dismissible(
          key: ValueKey(transaction.id ?? index),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) async {
            // update balance when deleting
            final prefs = await SharedPreferences.getInstance();
            double current = prefs.getDouble('total_balance') ?? 0.0;
            final delta =
                transaction.amount *
                (isExpense ? -1.0 : 1.0); // effect of this tx
            current -= delta; // remove its effect
            await prefs.setDouble('total_balance', current);
            setState(() {
              _totalBalance = current;
              _transactions.removeAt(index);
            });
            // also delete from DB
            if (transaction.id != null) {
              await dbService.deleteTransaction(transaction.id!);
            }
          },
          child: ListTile(
            tileColor: isDarkMode ? Colors.black12 : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 5.h,
            ),
            leading: Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: TransactionColors.values
                    .firstWhere(
                      (c) => c.name == transaction.category,
                      orElse: () => TransactionColors.more,
                    )
                    .color
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                transaction.icon,
                color: TransactionColors.values
                    .firstWhere(
                      (c) => c.name == transaction.category,
                      orElse: () => TransactionColors.more,
                    )
                    .color,
              ),
            ),
            title: Text(
              transaction.title,
              style: AppText.body16(
                context,
              ).copyWith(color: isDarkMode ? Colors.white : Colors.black),
            ),
            subtitle: Text(
              '${_getCategoryLabel(transaction.category)} • '
              '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
              style: AppText.body12grey(context).copyWith(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            trailing: Text(
              '${isExpense ? '-' : '+'}\$${transaction.amount.toStringAsFixed(2)}',
              style: AppText.body16(context).copyWith(
                color: isExpense ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddTransactionScreen(transaction: transaction),
                ),
              );
              if (result == true) {
                await _loadTransactions();
              }
            },
          ),
        );
      },
    );
  }
}
