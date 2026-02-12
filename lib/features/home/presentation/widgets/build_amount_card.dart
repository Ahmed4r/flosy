import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget buildAmountCard(
  BuildContext context,
  Widget buildPercentage(), // percentage chip
  double totalBalance,
  VoidCallback onEditBalance, // edit callback
  double spentRatio, // 0.0 - 1.0
  String currencySymbol, // currency symbol
) {
  return Container(
    width: double.infinity,
    height: 120.h,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20.r),
      gradient: const LinearGradient(
        colors: [Color(0xff131f38), Color(0xff121f31), Color(0xff153b37)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        tileMode: TileMode.decal,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: label + percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'home.total_balance'.tr(),
                style: AppText.body12grey(
                  context,
                ).copyWith(fontSize: 14.sp, color: Colors.white70),
              ),
              SizedBox(width: 8.w),
              buildPercentage(), // <-- percentage next to label
            ],
          ),
          SizedBox(height: 6.h),
          // Row 2: balance + edit icon
          Row(
            children: [
              Text(
                '${totalBalance.toStringAsFixed(2)} $currencySymbol',
                style: AppText.head24(context).copyWith(color: Colors.white),
              ),
              SizedBox(width: 8.w),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.edit, color: Colors.white70, size: 18),
                onPressed: onEditBalance,
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: spentRatio.clamp(0.0, 1.0), // <-- dynamic level
                  color: AppColors.greenColor,
                  backgroundColor: Colors.white24,
                  minHeight: 2.h,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'home.monthly_limit'.tr(),
                style: AppText.body12grey(
                  context,
                ).copyWith(fontSize: 10.sp, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
