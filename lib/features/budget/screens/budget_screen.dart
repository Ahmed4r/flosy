import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
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

  List<BudgetModel> _budgets = [];
  Map<String, double> _spentByCategory = {};
  bool _isLoading = true;

  // Category display metadata
  static final Map<String, Map<String, dynamic>> categoryMeta = {
    'food': {
      'label': 'Food & Dining',
      'icon': FontAwesomeIcons.burger,
      'color': Colors.orange,
    },
    'shopping': {
      'label': 'Shopping',
      'icon': FontAwesomeIcons.bagShopping,
      'color': Colors.purple,
    },
    'transport': {
      'label': 'Transportation',
      'icon': FontAwesomeIcons.car,
      'color': Colors.blue,
    },
    'fun': {
      'label': 'Entertainment',
      'icon': FontAwesomeIcons.film,
      'color': Colors.pink,
    },
    'rent': {
      'label': 'Rent',
      'icon': FontAwesomeIcons.house,
      'color': Colors.teal,
    },
    'bills': {
      'label': 'Bills & Utilities',
      'icon': FontAwesomeIcons.bolt,
      'color': Colors.amber,
    },
    'health': {
      'label': 'Health',
      'icon': FontAwesomeIcons.heartPulse,
      'color': Colors.red,
    },
    'salary': {
      'label': 'Salary',
      'icon': Icons.attach_money,
      'color': Colors.green,
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
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMonthSelector(),
                            SizedBox(height: 20.h),
                            if (_budgets.isNotEmpty) ...[
                              _buildMonthlySummaryCard(),
                              SizedBox(height: 30.h),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Budgets',
            style: AppText.head32(
              context,
            ).copyWith(fontWeight: FontWeight.bold, color: _textPrimary),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.settings_outlined,
              size: 26.sp,
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              color: AppColors.greenColor,
              size: 18.sp,
            ),
            SizedBox(width: 10.w),
            Text(
              DateFormat('MMMM yyyy').format(selectedDate),
              style: AppText.body16(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(width: 6.w),
            Icon(
              Icons.keyboard_arrow_down,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              size: 20.sp,
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
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24.r),
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
                'MONTHLY SUMMARY',
                style: AppText.body12(context).copyWith(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isOnTrack
                      ? AppColors.greenColor.withOpacity(0.15)
                      : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  isOnTrack ? 'On Track' : 'Over Budget',
                  style: AppText.body12(context).copyWith(
                    color: isOnTrack ? AppColors.greenColor : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${spent.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 44.sp,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                  height: 1,
                ),
              ),
              SizedBox(width: 8.w),
              Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Text(
                  '/ \$${budget.toStringAsFixed(0)}',
                  style: AppText.body18(context).copyWith(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Spent',
                style: AppText.body14(context).copyWith(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
              Text(
                '$percentage%',
                style: AppText.body14(
                  context,
                ).copyWith(fontWeight: FontWeight.bold, color: _textPrimary),
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
          SizedBox(height: 14.h),
          Center(
            child: Text(
              remaining >= 0
                  ? 'You have \$${remaining.toStringAsFixed(0)} left to spend'
                  : 'You are \$${remaining.abs().toStringAsFixed(0)} over budget',
              style: AppText.body14(
                context,
              ).copyWith(color: remaining >= 0 ? Colors.grey[500] : Colors.red),
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
          'Your Limits',
          style: AppText.head24(context).copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16.h),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _budgets.length,
          separatorBuilder: (_, __) => SizedBox(height: 14.h),
          itemBuilder: (context, index) {
            return _buildBudgetLimitCard(_budgets[index]);
          },
        ),
        SizedBox(height: 100.h),
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

    // Get display info from metadata, fallback to stored icon
    final meta = categoryMeta[budget.category];
    final displayIcon = meta != null ? meta['icon'] as IconData : budget.icon;
    final displayColor = meta != null
        ? meta['color'] as Color
        : AppColors.greenColor;
    final displayLabel = meta?['label'] ?? budget.category;

    return Dismissible(
      key: Key('budget_${budget.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 24.w),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Icon(Icons.delete_outline, color: Colors.white, size: 28.sp),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Budget'),
            content: Text('Remove the $displayLabel budget?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
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
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52.w,
                    height: 52.h,
                    decoration: BoxDecoration(
                      color: displayColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16.r),
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
                          style: AppText.body16(
                            context,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          budget.isRecurring ? 'Resets monthly' : 'One-time',
                          style: AppText.body12(
                            context,
                          ).copyWith(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${spent.toStringAsFixed(0)}',
                        style: AppText.body16(context).copyWith(
                          fontWeight: FontWeight.bold,
                          color: isOver ? Colors.red : _textPrimary,
                        ),
                      ),
                      Text(
                        'of \$${limit.toStringAsFixed(0)}',
                        style: AppText.body12(
                          context,
                        ).copyWith(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
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
                  if (isOver)
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 14.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Over budget',
                          style: AppText.body12(context).copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  else if (isNearLimit)
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 14.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Near Limit',
                          style: AppText.body12(context).copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      '$percentage% used',
                      style: AppText.body12(
                        context,
                      ).copyWith(color: Colors.grey[600]),
                    ),
                  Text(
                    remaining >= 0
                        ? '\$${remaining.toStringAsFixed(0)} left'
                        : '\$${remaining.abs().toStringAsFixed(0)} over',
                    style: AppText.body12(context).copyWith(
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
            Icon(
              FontAwesomeIcons.chartPie,
              size: 64.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 20.h),
            Text(
              'No budgets yet',
              style: AppText.head24(
                context,
              ).copyWith(color: Colors.grey[500], fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),
            Text(
              'Tap "New Budget" to create\nyour first spending limit',
              textAlign: TextAlign.center,
              style: AppText.body14(
                context,
              ).copyWith(color: Colors.grey[400], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewBudgetButton() {
    return Container(
      margin: EdgeInsets.only(bottom: 70.h),
      child: FloatingActionButton.extended(
        heroTag: 'new_budget',
        onPressed: () async {
          HapticFeedback.mediumImpact();
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddBudgetScreen()),
          );
          if (result == true) _loadData();
        },
        backgroundColor: AppColors.greenColor,
        elevation: 8,
        icon: Icon(Icons.add, color: Colors.white, size: 22.sp),
        label: Text(
          'New Budget',
          style: AppText.body16(
            context,
          ).copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
