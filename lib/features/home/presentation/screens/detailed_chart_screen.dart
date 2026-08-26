import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/home/data/model/transaction_model.dart';
import 'package:flosy/features/home/presentation/services/db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailedChartScreen extends StatefulWidget {
  final bool isArabic;

  const DetailedChartScreen({super.key, required this.isArabic});

  @override
  State<DetailedChartScreen> createState() => _DetailedChartScreenState();
}

class _DetailedChartScreenState extends State<DetailedChartScreen> {
  List<TransactionModel> _transactions = [];
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    getCurrencySymbol();
  }

  String currencySymbol = '\$';
  Future<String> getCurrencySymbol() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    currencySymbol = pref.getString('selected_currency') ?? '\$';
    return currencySymbol;
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final data = await dbService.getTransactions();

    // Add this check to prevent memory leaks and crashes if the screen is closed early
    if (!mounted) return;

    setState(() {
      _transactions = data;
      _isLoading = false;
    });
  }

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

  Map<String, double> get _expensesByCategory {
    final Map<String, double> categoryMap = {};
    for (var t in _transactions) {
      if (t.type == TransactionType.expense &&
          t.date.year == _selectedMonth.year &&
          t.date.month == _selectedMonth.month) {
        categoryMap[t.category] = (categoryMap[t.category] ?? 0) + t.amount;
      }
    }
    return categoryMap;
  }

  double get _totalExpenses =>
      _expensesByCategory.values.fold(0, (sum, val) => sum + val);

  double get _totalIncome => _transactions
      .where(
        (t) =>
            t.type == TransactionType.income &&
            t.date.year == _selectedMonth.year &&
            t.date.month == _selectedMonth.month,
      )
      .fold(0.0, (sum, t) => sum + t.amount);

  int get _transactionCount => _transactions
      .where(
        (t) =>
            t.type == TransactionType.expense &&
            t.date.year == _selectedMonth.year &&
            t.date.month == _selectedMonth.month,
      )
      .length;

  Color _getCategoryColor(String category, int index) {
    final colors = [
      AppColors.greenColor,
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.amber,
      Colors.cyan,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = AppTheme.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'home.detailed_chart'.tr(),
          style: AppText.body16(context).copyWith(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 20.sp,
          ),
        ),
        backgroundColor: isDarkMode
            ? AppColors.blackColor
            : AppColors.whiteColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonthSelector(isDarkMode),
                  SizedBox(height: 20.h),
                  _buildStatisticsCards(isDarkMode),
                  SizedBox(height: 24.h),
                  _buildPieChart(isDarkMode),
                  SizedBox(height: 24.h),
                  _buildCategoryBreakdown(isDarkMode),
                  SizedBox(height: 150.h),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthSelector(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black54 : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                );
              });
            },
            icon: Icon(
              Icons.chevron_left,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedMonth),
            style: AppText.body16(context).copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          IconButton(
            onPressed: () {
              final nextMonth = DateTime(
                _selectedMonth.year,
                _selectedMonth.month + 1,
              );
              if (nextMonth.isBefore(DateTime.now()) ||
                  nextMonth.month == DateTime.now().month) {
                setState(() {
                  _selectedMonth = nextMonth;
                });
              }
            },
            icon: Icon(
              Icons.chevron_right,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            isDarkMode,
            'home.total_expenses'.tr(),
            '${currencySymbol}${_totalExpenses.toStringAsFixed(0)}',
            Icons.trending_down,
            Colors.red,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            isDarkMode,
            'home.total_income'.tr(),
            '${currencySymbol}${_totalIncome.toStringAsFixed(0)}',
            Icons.trending_up,
            AppColors.greenColor,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            isDarkMode,
            'home.transactions'.tr(),
            '$_transactionCount',
            Icons.receipt_long,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    bool isDarkMode,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black54 : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: AppText.body16(context).copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppText.body12grey(context).copyWith(
              fontSize: 10.sp,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(bool isDarkMode) {
    if (_expensesByCategory.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32.w),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black54 : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isDarkMode ? Colors.white12 : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.pie_chart_outline, size: 64.sp, color: Colors.grey),
              SizedBox(height: 16.h),
              Text(
                'home.no_expenses'.tr(),
                style: AppText.body16(context).copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final colorList = _expensesByCategory.keys
        .toList()
        .asMap()
        .entries
        .map((e) => _getCategoryColor(e.value, e.key))
        .toList();

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black54 : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'home.expense_distribution'.tr(),
            style: AppText.body16(context).copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 20.h),
          PieChart(
            dataMap: _expensesByCategory,
            animationDuration: const Duration(milliseconds: 1000),
            chartRadius: MediaQuery.of(context).size.width / 2.2,
            colorList: colorList,
            initialAngleInDegree: 0,
            chartType: ChartType.ring,
            ringStrokeWidth: 28.w,
            centerWidget: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'home.total'.tr(),
                  style: AppText.body12grey(context).copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black54,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${currencySymbol}${_totalExpenses.toStringAsFixed(0)}',
                  style: AppText.head24(context).copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22.sp, // Reduced from 24.sp
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            legendOptions: const LegendOptions(showLegends: false),
            chartValuesOptions: const ChartValuesOptions(
              showChartValueBackground: true,
              showChartValues: true,
              showChartValuesInPercentage: true,
              showChartValuesOutside: false,
              decimalPlaces: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(bool isDarkMode) {
    if (_expensesByCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedCategories = _expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black54 : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'home.category_breakdown'.tr(),
            style: AppText.body16(context).copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 16.h),
          ...sortedCategories.asMap().entries.map((entry) {
            final index = entry.key;
            final categoryEntry = entry.value;
            final category = categoryEntry.key;
            final amount = categoryEntry.value;
            final percentage = (amount / _totalExpenses) * 100;
            final color = _getCategoryColor(category, index);

            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 16.w,
                        height: 16.w,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getCategoryLabel(category),
                              style: AppText.body14(context).copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              widget.isArabic
                                  ? '${'of_total'.tr()} ${percentage.toStringAsFixed(1)}%'
                                  : '${percentage.toStringAsFixed(1)}%',
                              style: AppText.body12grey(context).copyWith(
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${currencySymbol}${amount.toStringAsFixed(2)}',
                        style: AppText.body16(context).copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: isDarkMode
                          ? Colors.white12
                          : Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6.h,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
