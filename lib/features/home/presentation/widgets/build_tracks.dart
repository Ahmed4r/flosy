import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/settings/cubit/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
          icon: Icons.south_west_rounded,
          color: AppColors.greenColor,
          context: context,
        ),
      ),
      SizedBox(width: 14.w),
      Expanded(
        child: _buildTrackCard(
          title: 'home.expenses'.tr(),
          amount: totalExpenses,
          icon: Icons.north_east_rounded,
          color: Colors.redAccent,
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
    padding: EdgeInsets.all(18.w),
    decoration: BoxDecoration(
      color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      borderRadius: BorderRadius.circular(20.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
          blurRadius: 12,
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
            // Icon with glow
            Container(
              width: 42.w,
              height: 42.h,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 20.sp),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        Text(
          title,
          style: AppText.body12(context).copyWith(
            color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4.h),
        BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            String currency = '\$';
            if (state is SettingsLoaded) {
              currency = state.selectedCurrency;
            }
            return Text(
              '$currency ${amount.toStringAsFixed(1)}',
              style: AppText.body18(context).copyWith(
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
      ],
    ),
  );
}
