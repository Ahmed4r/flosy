import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/budget/data/model/budget_model.dart';
import 'package:flosy/features/home/presentation/services/db.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AddBudgetScreen extends StatefulWidget {
  final BudgetModel? budget; // Pass existing budget for edit mode

  const AddBudgetScreen({super.key, this.budget});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen>
    with SingleTickerProviderStateMixin {
  late bool isDarkMode;
  late TextEditingController _amountController;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  String selectedCategory = '';
  bool notifyAtThreshold = true;
  bool isRecurring = true;
  bool _isSaving = false;
  bool _showAllCategories = false;

  bool get isEditMode => widget.budget != null;

  final List<Map<String, dynamic>> categories = [
    {
      'id': 'food',
      'label': 'Food',
      'icon': FontAwesomeIcons.burger,
      'color': Colors.orange,
      'bgColor': const Color(0xFFFFF0E0),
      'darkBgColor': const Color(0xFF3D2E1A),
    },
    {
      'id': 'shopping',
      'label': 'Shopping',
      'icon': FontAwesomeIcons.bagShopping,
      'color': Colors.purple,
      'bgColor': const Color(0xFFF0E6FF),
      'darkBgColor': const Color(0xFF2D1F3D),
    },
    {
      'id': 'transport',
      'label': 'Travel',
      'icon': FontAwesomeIcons.car,
      'color': Colors.blue,
      'bgColor': const Color(0xFFE0F4FF),
      'darkBgColor': const Color(0xFF1A2D3D),
    },
    {
      'id': 'fun',
      'label': 'Fun',
      'icon': FontAwesomeIcons.film,
      'color': Colors.pink,
      'bgColor': const Color(0xFFFFE0F0),
      'darkBgColor': const Color(0xFF3D1A2D),
    },
    {
      'id': 'rent',
      'label': 'Rent',
      'icon': FontAwesomeIcons.house,
      'color': Colors.teal,
      'bgColor': const Color(0xFFE0F5F0),
      'darkBgColor': const Color(0xFF1A3D33),
    },
    {
      'id': 'bills',
      'label': 'Bills',
      'icon': FontAwesomeIcons.bolt,
      'color': Colors.amber,
      'bgColor': const Color(0xFFFFF8E0),
      'darkBgColor': const Color(0xFF3D351A),
    },
    {
      'id': 'health',
      'label': 'Health',
      'icon': FontAwesomeIcons.heartPulse,
      'color': Colors.red,
      'bgColor': const Color(0xFFFFE0E0),
      'darkBgColor': const Color(0xFF3D1A1A),
    },
    {
      'id': 'salary',
      'label': 'Salary',
      'icon': Icons.attach_money,
      'color': Colors.green,
      'bgColor': const Color(0xFFE0FFE8),
      'darkBgColor': const Color(0xFF1A3D20),
    },
  ];

  List<Map<String, dynamic>> get visibleCategories {
    if (_showAllCategories) return categories;
    return categories.take(6).toList();
  }

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    // Pre-fill if editing
    if (isEditMode) {
      final b = widget.budget!;
      _amountController.text = b.limitAmount.toStringAsFixed(0);
      selectedCategory = b.category;
      notifyAtThreshold = b.notifyAtThreshold;
      isRecurring = b.isRecurring;
    }

    _animController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isDarkMode = AppTheme.isDarkMode(context);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Color get _bgColor =>
      isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFF2F7F0);

  Color get _cardColor => isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;

  Color get _textPrimary => isDarkMode ? Colors.white : const Color(0xFF1A1A1A);

  Color get _textSecondary =>
      isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 28.h),
                      _buildAmountInput(),
                      SizedBox(height: 36.h),
                      _buildCategorySection(),
                      SizedBox(height: 28.h),
                      _buildOptionsCard(),
                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
              ),
              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      child: Row(
        children: [
          _buildCircleButton(
            icon: Icons.close,
            onTap: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            isEditMode ? 'Edit Budget' : 'New Budget',
            style: AppText.head24(
              context,
            ).copyWith(fontWeight: FontWeight.bold, color: _textPrimary),
          ),
          const Spacer(),
          SizedBox(width: 44.w),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44.w,
        height: 44.h,
        decoration: BoxDecoration(
          color: _cardColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20.sp, color: _textPrimary),
      ),
    );
  }

  // ─── AMOUNT INPUT ────────────────────────────────────

  Widget _buildAmountInput() {
    return Column(
      children: [
        Text(
          'MONTHLY LIMIT',
          style: AppText.body12(context).copyWith(
            color: _textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 24.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 20.h),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(28.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '\$',
                style: TextStyle(
                  fontSize: 36.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.greenColor.withOpacity(0.6),
                ),
              ),
              SizedBox(width: 4.w),
              IntrinsicWidth(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 52.sp,
                    fontWeight: FontWeight.w300,
                    color: _textPrimary,
                    height: 1.1,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(7),
                  ],
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontSize: 52.sp,
                      fontWeight: FontWeight.w300,
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      height: 1.1,
                    ),
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildArrowButton(
                    icon: Icons.keyboard_arrow_up_rounded,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      final current = int.tryParse(_amountController.text) ?? 0;
                      _amountController.text = (current + 100).toString();
                    },
                  ),
                  SizedBox(height: 4.h),
                  _buildArrowButton(
                    icon: Icons.keyboard_arrow_down_rounded,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      final current = int.tryParse(_amountController.text) ?? 0;
                      if (current >= 100) {
                        _amountController.text = (current - 100).toString();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArrowButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.w,
        height: 30.h,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, size: 22.sp, color: _textSecondary),
      ),
    );
  }

  // ─── CATEGORIES ──────────────────────────────────────

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Text(
            'CHOOSE CATEGORY',
            style: AppText.body12(context).copyWith(
              color: _textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ),
        SizedBox(height: 20.h),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Wrap(
            spacing: 14.w,
            runSpacing: 18.h,
            children: [
              ...visibleCategories.map((cat) {
                final isSelected = selectedCategory == cat['id'];
                return _buildCategoryChip(cat, isSelected);
              }),
              // "More" / "Less" toggle
              _buildMoreToggle(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(Map<String, dynamic> cat, bool isSelected) {
    final color = cat['color'] as Color;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => selectedCategory = cat['id']);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: 74.w,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: 68.w,
              height: 68.h,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? cat['darkBgColor'] as Color
                    : cat['bgColor'] as Color,
                borderRadius: BorderRadius.circular(20.r),
                border: isSelected
                    ? Border.all(color: AppColors.greenColor, width: 2.5)
                    : Border.all(color: Colors.transparent, width: 2.5),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.greenColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Icon(cat['icon'] as IconData, color: color, size: 26.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              cat['label'],
              style: AppText.body12(context).copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _textPrimary : _textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreToggle() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _showAllCategories = !_showAllCategories);
      },
      child: SizedBox(
        width: 74.w,
        child: Column(
          children: [
            Container(
              width: 68.w,
              height: 68.h,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[850] : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                _showAllCategories
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.grid_view_rounded,
                color: _textSecondary,
                size: 26.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _showAllCategories ? 'Less' : 'More',
              style: AppText.body12(
                context,
              ).copyWith(fontWeight: FontWeight.w500, color: _textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── OPTIONS CARD ────────────────────────────────────

  Widget _buildOptionsCard() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Notify at 80%
          _buildOptionRow(
            icon: Icons.notifications_active_outlined,
            iconColor: AppColors.greenColor,
            iconBgColor: AppColors.greenColor.withOpacity(0.15),
            title: 'Notify at 80%',
            subtitle: 'Get a heads-up before\noverspending',
            trailing: Switch.adaptive(
              value: notifyAtThreshold,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => notifyAtThreshold = v);
              },
              activeColor: Colors.white,
              activeTrackColor: AppColors.greenColor,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: isDarkMode
                  ? Colors.grey[700]
                  : Colors.grey[300],
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Divider(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              thickness: 0.5,
            ),
          ),

          // Recurring Budget
          _buildOptionRow(
            icon: Icons.sync_rounded,
            iconColor: isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
            iconBgColor: isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
            title: 'Recurring Budget',
            subtitle: isRecurring ? 'Reset every month' : 'One-time budget',
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey[400],
              size: 16.sp,
            ),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => isRecurring = !isRecurring);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Container(
              width: 46.w,
              height: 46.h,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(icon, color: iconColor, size: 22.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.body16(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: AppText.body12(
                      context,
                    ).copyWith(color: _textSecondary, height: 1.3),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  // ─── CREATE BUTTON ───────────────────────────────────

  Widget _buildCreateButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 20.h),
      child: GestureDetector(
        onTap: _isSaving ? null : _onSave,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 58.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.greenColor,
                AppColors.greenColor.withOpacity(0.75),
              ],
            ),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.greenColor.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: _isSaving
                ? SizedBox(
                    width: 24.w,
                    height: 24.h,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    isEditMode ? 'Update Budget' : 'Create Budget',
                    style: AppText.body18(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ─── SAVE LOGIC ──────────────────────────────────────

  Future<void> _onSave() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText) ?? 0;

    if (amount <= 0) {
      _showSnack('Please set a budget amount', Colors.red);
      return;
    }
    if (selectedCategory.isEmpty) {
      _showSnack('Please select a category', Colors.red);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Find the selected category data
      final catData = categories.firstWhere(
        (c) => c['id'] == selectedCategory,
        orElse: () => categories.first,
      );
      final iconData = catData['icon'] as IconData;

      final budget = BudgetModel(
        id: widget.budget?.id,
        category: selectedCategory,
        limitAmount: amount,
        iconCodePoint: iconData.codePoint,
        iconFontFamily: iconData.fontFamily ?? 'MaterialIcons',
        iconFontPackage: iconData.fontPackage,
        notifyAtThreshold: notifyAtThreshold,
        isRecurring: isRecurring,
      );

      if (isEditMode) {
        await dbService.updateBudget(budget);
      } else {
        await dbService.addBudget(budget);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnack('Failed to save budget', Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      ),
    );
  }
}
