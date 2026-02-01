import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget buildTracks(
  BuildContext context,
  dynamic totalIncome,
  dynamic totalExpenses,
) {
  return Row(
    children: [
      Expanded(
        child: _buildTrackCard(
          title: 'home.income'.tr(),
          amount: totalIncome,
          icon: Icons.arrow_downward,
          color: Colors.green,
          context: context,
        ),
      ),
      SizedBox(width: 16.w),
      Expanded(
        child: _buildTrackCard(
          title: 'home.expenses'.tr(),
          amount: totalExpenses,
          icon: Icons.arrow_upward,
          color: Colors.red,
          context: context,
        ),
      ),
    ],
  );
}

Widget _buildTrackCard({
  required String title,
  required double amount,
  required IconData icon,
  required Color color,
  required BuildContext context,
}) {
  bool isDarkMode = AppTheme.isDarkMode(context);
  return Container(
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(
      color: isDarkMode ? AppColors.blackColor : AppColors.whiteColor,
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(15.r),
        bottomLeft: Radius.circular(15.r),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.3),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 8.h),
        Text(title, style: AppText.body12grey(context)),
        SizedBox(height: 4.h),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: AppText.body16(context).copyWith(
            color: isDarkMode ? AppColors.whiteColor : AppColors.blackColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
