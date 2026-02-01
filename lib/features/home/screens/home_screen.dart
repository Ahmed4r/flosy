import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/home/model/transaction_model.dart';
import 'package:flosy/features/home/screens/add_transaction_screen.dart';
import 'package:flosy/features/home/widgets/build_amount_card.dart';
import 'package:flosy/features/home/widgets/build_chart.dart';
import 'package:flosy/features/home/widgets/build_header.dart';
import 'package:flosy/features/home/widgets/build_tracks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  final List<TransactionModel> transactions = [
    TransactionModel(
      id: '1',
      title: 'Grocery Shopping',
      amount: 50.0,
      date: DateTime.now().subtract(const Duration(days: 2)),
      category: 'Food',
      type: TransactionType.expense,
      icon: Icons.shopping_cart,
    ),
  ];
  double get totalIncome => transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalExpenses => transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = AppTheme.isDarkMode(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action to add a new transaction
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
        },
        backgroundColor: AppColors.greenColor,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.r),
        ),
        child: Icon(Icons.add, size: 24.sp, color: AppColors.blackColor),
      ),

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
                SizedBox(height: 20.h),
                buildAmountCard(context, buildView),
                SizedBox(height: 20.h),
                buildTracks(context, totalIncome, totalExpenses),
                SizedBox(height: 20.h),
                buildChart(context),
                SizedBox(height: 10.h),
                buildRecentTransactions(isDarkMode),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildView() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: const Color.fromARGB(41, 255, 255, 255),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.arrowUpRightDots,
            size: 12.sp,
            color: AppColors.greenColor,
          ),
          SizedBox(width: 4.w),
          Text(
            getValue(),
            style: AppText.body12grey(
              context,
            ).copyWith(color: AppColors.greenColor),
          ),
        ],
      ),
    );
  }

  String getValue() {
    // Placeholder function to return a value
    return '+2.5%';
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
    if (transactions.isEmpty) {
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
      itemCount: transactions.length,
      separatorBuilder: (context, index) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final isExpense = transaction.type == TransactionType.expense;

        return ListTile(
          tileColor: isDarkMode ? Colors.black12 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
          leading: Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: isExpense
                  ? Colors.red.withOpacity(0.1)
                  : AppColors.greenColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              transaction.icon,
              color: isExpense ? Colors.red : AppColors.greenColor,
            ),
          ),
          title: Text(
            transaction.title,
            style: AppText.body16(
              context,
            ).copyWith(color: isDarkMode ? Colors.white : Colors.black),
          ),
          subtitle: Text(
            '${transaction.category} • ${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
            style: AppText.body12grey(
              context,
            ).copyWith(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
          ),
          trailing: Text(
            '${isExpense ? '-' : '+'}\$${transaction.amount.toStringAsFixed(2)}',
            style: AppText.body16(context).copyWith(
              color: isExpense ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
