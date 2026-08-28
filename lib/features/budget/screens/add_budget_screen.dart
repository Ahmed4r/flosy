import 'dart:developer' as developer;
import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/features/budget/data/model/budget_model.dart';
import 'package:flosy/features/home/presentation/services/db.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Typed category configuration — avoids FaIconData→IconData cast failures
/// on the DDC/JS web runtime.
/// icon is dynamic because FaIconData is not a Dart subtype of IconData.
class _CategoryConfig {
  final String labelKey;
  final dynamic icon;
  final Color color;
  const _CategoryConfig({
    required this.labelKey,
    required this.icon,
    required this.color,
  });
}

class AddBudgetScreen extends StatefulWidget {
  final BudgetModel? budget;
  final String? currencySymbol;

  const AddBudgetScreen({super.key, this.budget, this.currencySymbol});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String? _selectedCategory;
  bool _isRecurring = true;
  bool _notifyAt80 = true;
  bool _isLoading = false;
  String? _currencySymbol;

  // Category configuration with proper translations
  static final Map<String, _CategoryConfig> categories = {
    'food': _CategoryConfig(
      labelKey: 'transaction.categories.food',
      icon: FontAwesomeIcons.burger,
      color: Colors.orange,
    ),
    'shopping': _CategoryConfig(
      labelKey: 'transaction.categories.shopping',
      icon: FontAwesomeIcons.bagShopping,
      color: Colors.purple,
    ),
    'transport': _CategoryConfig(
      labelKey: 'transaction.categories.transport',
      icon: FontAwesomeIcons.car,
      color: Colors.green,
    ),
    'fun': _CategoryConfig(
      labelKey: 'transaction.categories.fun',
      icon: FontAwesomeIcons.film,
      color: Colors.red,
    ),
    'rent': _CategoryConfig(
      labelKey: 'transaction.categories.rent',
      icon: FontAwesomeIcons.house,
      color: Colors.blue,
    ),
    'health': _CategoryConfig(
      labelKey: 'transaction.categories.health',
      icon: FontAwesomeIcons.heartPulse,
      color: Colors.teal,
    ),
  };

  @override
  void initState() {
    super.initState();
    developer.log('AddBudgetScreen initialized', name: 'AddBudget');

    if (widget.budget != null) {
      developer.log(
        'Editing existing budget: ${widget.budget!.category}',
        name: 'AddBudget',
      );
      _selectedCategory = widget.budget!.category;
      _amountController.text = widget.budget!.limitAmount.toStringAsFixed(0);
      _isRecurring = widget.budget!.isRecurring;
      _notifyAt80 = widget.budget!.notifyAtThreshold;
    } else {
      developer.log('Creating new budget', name: 'AddBudget');
    }
    _currencySymbol = widget.currencySymbol;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    developer.log('Save budget button pressed', name: 'AddBudget');

    if (!_formKey.currentState!.validate()) {
      developer.log('Form validation failed', name: 'AddBudget');
      return;
    }

    if (_selectedCategory == null) {
      developer.log('No category selected', name: 'AddBudget');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('budget.category_required'.tr()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    developer.log('Starting budget save process', name: 'AddBudget');

    try {
      final amount = double.parse(_amountController.text);
      developer.log('Amount parsed: $amount', name: 'AddBudget');

      final now = DateTime.now();
      final categoryData = categories[_selectedCategory];

      if (categoryData == null) {
        throw Exception('Invalid category: $_selectedCategory');
      }

      // Access icon fields via dynamic — FaIconData is not a Dart subtype of IconData.
      final dynamic iconData = categoryData.icon;

      final int codePoint = iconData.codePoint;
      final String fontFamily =
          iconData.fontFamily ?? 'FontAwesomeSolid';
      final String? fontPackage = iconData.fontPackage;

      final budget = BudgetModel(
        id: widget.budget?.id,
        category: _selectedCategory!,
        limitAmount: amount,
        period: 'monthly',
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 1, 0),
        isRecurring: _isRecurring,
        notifyAtThreshold: _notifyAt80,
        notifyPercent: 80,
        createdAt: widget.budget?.createdAt ?? now,
        iconCodePoint: codePoint,
        iconFontFamily: fontFamily,
        iconFontPackage: fontPackage,
      );
      developer.log(
        'Budget object created: category=${budget.category}, amount=${budget.limitAmount}, recurring=${budget.isRecurring}',
        name: 'AddBudget',
      );

      if (widget.budget != null) {
        developer.log(
          'Updating existing budget with id: ${widget.budget!.id}',
          name: 'AddBudget',
        );
        await dbService.updateBudget(budget);
        developer.log('Budget updated successfully', name: 'AddBudget');
      } else {
        developer.log('Adding new budget', name: 'AddBudget');
        final id = await dbService.addBudget(budget);
        developer.log(
          'Budget added successfully with id: $id',
          name: 'AddBudget',
        );
      }

      if (mounted) {
        developer.log('Navigating back with success', name: 'AddBudget');
        Navigator.pop(context, true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.budget != null
                  ? 'budget.updated_successfully'.tr()
                  : 'budget.created_successfully'.tr(),
            ),
            backgroundColor: AppColors.greenColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error saving budget',
        name: 'AddBudget',
        error: e.toString(),
        stackTrace: stackTrace,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        developer.log('Save process completed', name: 'AddBudget');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppTheme.isDarkMode(context);
    final bgColor = isDarkMode
        ? const Color(0xFF0A0A0A)
        : const Color(0xFFF5F5F5);
    final cardColor = isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () {
            developer.log('Close button pressed', name: 'AddBudget');
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.budget != null ? 'budget.edit'.tr() : "budget.new_budget".tr(),
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 8.h),

              // Monthly Limit Label
              Text(
                'budget.monthly_summary'.tr(),
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 20.h),

              // Amount Input with up/down arrows
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Up arrow
                    IconButton(
                      icon: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: Colors.grey[400],
                        size: 28.sp,
                      ),
                      onPressed: () {
                        final current =
                            double.tryParse(_amountController.text) ?? 0;
                        _amountController.text = (current + 10).toStringAsFixed(
                          0,
                        );
                      },
                    ),
                    // Amount display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: Text(
                            _currencySymbol ?? '\$',
                            style: TextStyle(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.w300,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: IntrinsicWidth(
                            child: TextFormField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                              textAlign: TextAlign.center,

                              style: TextStyle(
                                fontSize: 64.sp,
                                fontWeight: FontWeight.w300,
                                color: isDarkMode ? Colors.white : Colors.black,
                                height: 1,
                              ),
                              decoration: InputDecoration(
                                fillColor: Colors.transparent,
                                hintText: '0',
                                hintStyle: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 64.sp,
                                  fontWeight: FontWeight.w300,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return null;
                                }
                                final amount = double.tryParse(value);
                                if (amount == null || amount <= 0) {
                                  return 'budget.invalid_amount'.tr();
                                }
                                return null;
                              },
                              onChanged: (value) {
                                developer.log(
                                  'Amount changed: $value',
                                  name: 'AddBudget',
                                );
                                setState(() {});
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Down arrow
                    IconButton(
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey[400],
                        size: 28.sp,
                      ),
                      onPressed: () {
                        final current =
                            double.tryParse(_amountController.text) ?? 0;
                        if (current > 10) {
                          _amountController.text = (current - 10)
                              .toStringAsFixed(0);
                        }
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),

              // Choose Category Label
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "budget.select_category".tr(),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Category Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16.h,
                  crossAxisSpacing: 16.w,
                  childAspectRatio: 0.9, // Increased from 0.85
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final key = categories.keys.elementAt(index);
                  final cat = categories[key]!;
                  final isSelected = _selectedCategory == key;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      developer.log(
                        'Category selected: $key',
                        name: 'AddBudget',
                      );
                      setState(() => _selectedCategory = key);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Added
                      children: [
                        Container(
                          width: 60.w, // Reduced from 64.w
                          height: 60.h, // Reduced from 64.h
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cat.color
                                : cat.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(
                              18.r,
                            ), // Reduced from 20.r
                            border: isSelected
                                ? Border.all(
                                    color: cat.color,
                                    width: 2.5, // Reduced from 3
                                  )
                                : null,
                          ),
                          child: Center(
                            child: FaIcon(
                              cat.icon,
                              color: isSelected
                                  ? Colors.white
                                  : cat.color,
                              size: 24.sp,
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h), // Reduced from 8.h
                        Flexible(
                          // Added Flexible
                          child: Text(
                            cat.labelKey.tr(),
                            style: TextStyle(
                              fontSize: 11.sp, // Reduced from 12.sp
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? Colors.grey[300]
                                  : Colors.grey[800],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              SizedBox(height: 32.h),

              // Notify at 80%
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: AppColors.greenColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.notifications_active_outlined,
                        color: AppColors.greenColor,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'budget.notify_on_80'.tr(),
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            'budget.get_a_heads_up_before_overspending'.tr(),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _notifyAt80,
                      onChanged: (value) {
                        HapticFeedback.lightImpact();
                        setState(() => _notifyAt80 = value);
                      },
                      activeColor: AppColors.greenColor,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // Recurring Budget Toggle
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.autorenew_rounded,
                        color: Colors.blue,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'budget.recurring_budget'.tr(),
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            _isRecurring
                                ? 'budget.reset_every_month'.tr()
                                : 'budget.one_time'.tr(),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isRecurring,
                      onChanged: (value) {
                        HapticFeedback.lightImpact();
                        developer.log(
                          'Recurring budget toggled: $value',
                          name: 'AddBudget',
                        );
                        setState(() => _isRecurring = value);
                      },
                      activeColor: Colors.blue,
                    ),
                  ],
                ),
              ),

              // Info message based on recurring state
              if (_isRecurring || !_isRecurring) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: _isRecurring
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _isRecurring
                          ? Colors.blue.withOpacity(0.3)
                          : Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isRecurring
                            ? Icons.info_outline
                            : Icons.calendar_today_outlined,
                        color: _isRecurring ? Colors.blue : Colors.orange,
                        size: 18.sp,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          _isRecurring
                              ? 'budget.recurring_desc'.tr()
                              : 'budget.one_time_desc'.tr(),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: _isRecurring
                                ? Colors.blue[700]
                                : Colors.orange[700],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 40.h),

              // Create Budget Button
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveBudget,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.greenColor,
                    disabledBackgroundColor: AppColors.greenColor.withOpacity(
                      0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24.w,
                          height: 24.h,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          widget.budget != null
                              ? 'budget.update_budget'.tr()
                              : 'budget.create_budget'.tr(),
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
