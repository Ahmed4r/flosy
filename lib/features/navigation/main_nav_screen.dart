import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/budget/screens/budget_screen.dart';
import 'package:flosy/features/home/presentation/screens/add_transaction_screen.dart';
import 'package:flosy/features/home/presentation/screens/detailed_chart_screen.dart';
import 'package:flosy/features/home/presentation/screens/home_screen.dart';
import 'package:flosy/features/settings/screens/main_setting_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' as math;

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;
  late final AnimationController _fabAnimController;
  late final Animation<double> _fabScaleAnim;

  final List<_NavItem> _navItems = [
    _NavItem(
      icon: FontAwesomeIcons.house,
      activeIcon: FontAwesomeIcons.house,
      label: 'Home',
    ),
    _NavItem(
      icon: FontAwesomeIcons.chartPie,
      activeIcon: FontAwesomeIcons.chartPie,
      label: 'Budget',
    ),
    _NavItem(
      icon: FontAwesomeIcons.chartLine,
      activeIcon: FontAwesomeIcons.chartLine,
      label: 'Analytics',
    ),
    _NavItem(
      icon: FontAwesomeIcons.gear,
      activeIcon: FontAwesomeIcons.gear,
      label: 'Settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabScaleAnim = CurvedAnimation(
      parent: _fabAnimController,
      curve: Curves.elasticOut,
    );
    _fabAnimController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  bool _isArabic(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ar';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppTheme.isDarkMode(context);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => _currentIndex = i),
        children: [
          const HomeScreen(),
          const BudgetScreen(),
          DetailedChartScreen(isArabic: _isArabic(context)),
          const MainSettingScreen(),
        ],
      ),
      extendBody: true,
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnim,
        child: _buildFab(isDarkMode),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(isDarkMode),
    );
  }

  // ─── FAB ─────────────────────────────────────────────

  Widget _buildFab(bool isDarkMode) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        final result = await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AddTransactionScreen(),
            transitionsBuilder: (_, anim, __, child) {
              return SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                    ),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
        if (result == true && _currentIndex == 0) {
          // Trigger refresh on home screen
          setState(() {});
        }
      },
      child: Container(
        width: 60.w,
        height: 60.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.greenColor,
              AppColors.greenColor.withOpacity(0.75),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.greenColor.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(Icons.add_rounded, color: Colors.white, size: 30.sp),
      ),
    );
  }

  // ─── BOTTOM NAV ──────────────────────────────────────

  Widget _buildBottomNav(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        child: Container(
          height: 80.h,
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_navItems.length, (index) {
                  // Add spacing in the middle for the FAB
                  if (index == 2) {
                    return Expanded(
                      child: Row(
                        children: [
                          SizedBox(width: 28.w), // FAB gap
                          Expanded(child: _buildNavItem(index, isDarkMode)),
                        ],
                      ),
                    );
                  }
                  if (index == 1) {
                    return Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _buildNavItem(index, isDarkMode)),
                          SizedBox(width: 28.w), // FAB gap
                        ],
                      ),
                    );
                  }
                  return Expanded(child: _buildNavItem(index, isDarkMode));
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, bool isDarkMode) {
    final isActive = _currentIndex == index;
    final item = _navItems[index];

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              width: isActive ? 24.w : 0,
              height: 3.h,
              margin: EdgeInsets.only(bottom: 6.h),
              decoration: BoxDecoration(
                color: AppColors.greenColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            // Icon
            AnimatedScale(
              scale: isActive ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: FaIcon(
                isActive ? item.activeIcon : item.icon,
                size: 20.sp,
                color: isActive
                    ? AppColors.greenColor
                    : isDarkMode
                    ? Colors.grey[600]
                    : Colors.grey[400],
              ),
            ),
            SizedBox(height: 4.h),
            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? AppColors.greenColor
                    : isDarkMode
                    ? Colors.grey[600]
                    : Colors.grey[400],
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
