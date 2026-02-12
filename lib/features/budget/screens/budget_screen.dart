import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/features/budget/data/model/budget_model.dart';
import 'package:flosy/features/budget/screens/add_budget_screen.dart';
import 'package:flosy/features/home/presentation/services/db.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  DateTime selectedDate = DateTime.now();
  late bool isDarkMode;
  Future<void> refresh() async {
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadData()]);
    if (mounted) setState(() => _isLoading = false);
  }

  List<BudgetModel> _budgets = [];
  Map<String, double> _spentByCategory = {};
  bool _isLoading = true;

  // Category display metadata
  static final Map<String, Map<String, dynamic>> categoryMeta = {
    'food': {
      'labelKey': 'transaction.categories.food',
      'icon': FontAwesomeIcons.burger,
      'color': Colors.orange,
    },
    'shopping': {
      'labelKey': 'transaction.categories.shopping',
      'icon': FontAwesomeIcons.bagShopping,
      'color': Colors.purple,
    },
    'transport': {
      'labelKey': 'transaction.categories.transport',
      'icon': FontAwesomeIcons.car,
      'color': Colors.green,
    },
    'fun': {
      'labelKey': 'transaction.categories.fun',
      'icon': FontAwesomeIcons.film,
      'color': Colors.red,
    },
    'rent': {
      'labelKey': 'transaction.categories.rent',
      'icon': FontAwesomeIcons.house,
      'color': Colors.blue,
    },
    'health': {
      'labelKey': 'transaction.categories.health',
      'icon': FontAwesomeIcons.heartPulse,
      'color': Colors.teal,
    },
    'salary': {
      'labelKey': 'transaction.categories.salary',
      'icon': Icons.attach_money,
      'color': Colors.indigo,
    },
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isDarkMode = AppTheme.isDarkMode(context);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final budgets = await dbService.getBudgets();
      final spent = await dbService.getSpentByCategory(
        selectedDate.year,
        selectedDate.month,
      );
      if (mounted) {
        setState(() {
          _budgets = budgets;
          _spentByCategory = spent;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get totalBudget => _budgets.fold(0.0, (sum, b) => sum + b.limitAmount);

  double get totalSpent {
    double total = 0;
    for (final b in _budgets) {
      total += _spentByCategory[b.category] ?? 0;
    }
    return total;
  }

  Color get _bgColor =>
      isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5);

  Color get _cardColor => isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;

  Color get _textPrimary => isDarkMode ? Colors.white : Colors.black;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.greenColor,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppColors.greenColor,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 100.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMonthSelector(),
                            SizedBox(height: 20.h),
                            if (_budgets.isNotEmpty) ...[
                              _buildMonthlySummaryCard(),
                              SizedBox(height: 24.h),
                              _buildLimitsSection(),
                            ] else
                              _buildEmptyState(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildNewBudgetButton(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'budget.title'.tr(),
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(primary: AppColors.greenColor),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => selectedDate = picked);
          _loadData();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.greenColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.greenColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              color: AppColors.greenColor,
              size: 16.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              DateFormat('MMMM yyyy').format(selectedDate),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.greenColor,
              ),
            ),
            SizedBox(width: 6.w),
            Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.greenColor,
              size: 18.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySummaryCard() {
    final budget = totalBudget;
    final spent = totalSpent;
    final percentage = budget > 0 ? (spent / budget * 100).toInt() : 0;
    final remaining = budget - spent;
    final isOnTrack = percentage <= 75;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'budget.monthly_summary'.tr(),
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: isOnTrack
                      ? AppColors.greenColor.withOpacity(0.15)
                      : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  isOnTrack
                      ? "budget.on_track".tr()
                      : 'budget.over_budget'.tr(),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isOnTrack ? AppColors.greenColor : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\$${spent.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                style: TextStyle(
                  fontSize: 42.sp,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                  height: 1,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '/ \$${budget.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "budget.total_spent".tr(),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0,
              minHeight: 10.h,
              backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isOnTrack ? AppColors.greenColor : Colors.orange,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Center(
            child: Text(
              remaining >= 0
                  ? 'budget.you_have_left'.tr(
                      args: [remaining.toStringAsFixed(0)],
                    )
                  : 'budget.you_are_over'.tr(
                      args: [remaining.abs().toStringAsFixed(0)],
                    ),
              style: TextStyle(
                fontSize: 12.sp,
                color: remaining >= 0 ? Colors.grey[500] : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'budget.your_limits'.tr(),
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        SizedBox(height: 16.h),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _budgets.length,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            return _buildBudgetLimitCard(_budgets[index]);
          },
        ),
      ],
    );
  }

  Widget _buildBudgetLimitCard(BudgetModel budget) {
    final spent = _spentByCategory[budget.category] ?? 0;
    final limit = budget.limitAmount;
    final percentage = limit > 0 ? (spent / limit * 100).toInt() : 0;
    final remaining = limit - spent;
    final isNearLimit = percentage >= 90;
    final isOver = spent > limit;

    final meta = categoryMeta[budget.category];
    final displayIcon = meta != null ? meta['icon'] as IconData : budget.icon;
    final displayColor = meta != null
        ? meta['color'] as Color
        : AppColors.greenColor;
    final displayLabel = meta != null
        ? (meta['labelKey'] as String).tr()
        : budget.category;

    return Dismissible(
      key: Key('budget_${budget.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Icon(Icons.delete_outline, color: Colors.white, size: 24.sp),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text('budget.delete_budget'.tr()),
            content: Text(
              '${"budget.remove_the".tr()} $displayLabel ${"budget.budget".tr()}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'budget.cancel'.tr(),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'budget.delete'.tr(),
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        if (budget.id != null) {
          await dbService.deleteBudget(budget.id!);
          _loadData();
        }
      },
      child: GestureDetector(
        onTap: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => AddBudgetScreen(budget: budget)),
          );
          if (result == true) _loadData();
        },
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: displayColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(displayIcon, color: displayColor, size: 22.sp),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayLabel,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          budget.isRecurring
                              ? "budget.resets_monthly".tr()
                              : "budget.one_time".tr(),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${spent.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: isOver ? Colors.red : _textPrimary,
                        ),
                      ),
                      Text(
                        '${"budget.of".tr()} \$${limit.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: LinearProgressIndicator(
                  value: limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0,
                  minHeight: 8.h,
                  backgroundColor: isDarkMode
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOver
                        ? Colors.red
                        : isNearLimit
                        ? Colors.orange
                        : AppColors.greenColor,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (isOver)
                        Icon(
                          Icons.warning_rounded,
                          color: Colors.red,
                          size: 14.sp,
                        )
                      else if (isNearLimit)
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 14.sp,
                        ),
                      if (isOver || isNearLimit) SizedBox(width: 4.w),
                      Text(
                        isOver
                            ? "budget.over_budget".tr()
                            : isNearLimit
                            ? "budget.near_limit".tr()
                            : '$percentage% ${"budget.used".tr()}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isOver
                              ? Colors.red
                              : isNearLimit
                              ? Colors.orange
                              : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    remaining >= 0
                        ? '\$${remaining.toStringAsFixed(0)} ${"budget.left".tr()}'
                        : '\$${remaining.abs().toStringAsFixed(0)} ${"budget.over".tr()}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isOver
                          ? Colors.red
                          : isNearLimit
                          ? Colors.orange
                          : AppColors.greenColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.only(top: 80.h),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pie_chart_outline_rounded,
                size: 40.sp,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'budget.no_budgets'.tr(),
              style: TextStyle(
                fontSize: 20.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'budget.tap_new_budget_to_create'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewBudgetButton() {
    return Container(
      margin: EdgeInsets.only(bottom: 80.h, right: 4.w),
      child: FloatingActionButton.extended(
        heroTag: "new_budget",
        onPressed: () async {
          HapticFeedback.mediumImpact();
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddBudgetScreen()),
          );
          if (result == true) _loadData();
        },
        backgroundColor: Colors.black,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.r),
        ),
        icon: Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: AppColors.greenColor,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.add, color: Colors.white, size: 18.sp),
        ),
        label: Text(
          "budget.new_budget".tr(),
          style: TextStyle(
            fontSize: 15.sp,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
