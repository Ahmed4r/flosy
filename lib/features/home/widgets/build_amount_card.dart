import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget buildAmountCard(BuildContext context, Widget buildView()) {
  return Container(
    width: double.infinity,
    height: 120.h,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20.r),
      gradient: LinearGradient(
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
          Row(
            children: [
              Text(
                'home.total_balance'.tr(),
                style: AppText.body12grey(
                  context,
                ).copyWith(fontSize: 14.sp, color: Colors.white70),
              ),
              Spacer(),
              buildView(),
            ],
          ),
          Text(
            '\$12,345.67',
            style: AppText.head24(context).copyWith(color: Colors.white),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: 0.7,
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
