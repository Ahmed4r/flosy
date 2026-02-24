import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/home/data/model/transaction_model.dart';
import 'package:flosy/features/home/presentation/screens/recording_screen.dart';
import 'package:flosy/features/settings/cubit/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../settings/cubit/settings_state.dart';
import '../cubit/home_cubit.dart';

Widget buildAmountCard(
  BuildContext context,
  Widget Function() buildPercentage,
  double totalBalance,
  VoidCallback onEditBalance,
  double spentRatio,
  bool isDarkMode,
  bool isArabic,
) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24.r),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDarkMode
            ? [
                const Color(0xFF1A2E1A),
                const Color(0xFF0D1F1A),
                const Color(0xFF162A22),
              ]
            : [Colors.white, Colors.white.withOpacity(0.9)],
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.greenColor.withOpacity(isDarkMode ? 0.15 : 0.3),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: -4,
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -30.w,
            top: -30.h,
            child: Container(
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            left: -20.w,
            bottom: -40.h,
            child: Container(
              width: 100.w,
              height: 100.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(22.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: label + percentage badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'home.total_balance'.tr(),
                      style: AppText.body14(context).copyWith(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.7)
                            : Colors.black.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    buildPercentage(),
                  ],
                ),
                SizedBox(height: 10.h),

                // Balance amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: BlocBuilder<SettingsCubit, SettingsState>(
                        builder: (context, state) {
                          String currency = 'EGP';
                          if (state is SettingsLoaded) {
                            currency = state.selectedCurrency;
                          }
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '$currency ${totalBalance.toStringAsFixed(0)}',
                              style: AppText.head32(context).copyWith(
                                color: isDarkMode ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 8.w),
                    InkWell(
                      onTap: () async {
                        // 1. انتظر حتى تنتهي صفحة التسجيل ويتم إغلاقها
                        final TransactionModel? tx =
                            await Navigator.push<TransactionModel?>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RecordingPage(),
                              ),
                            );

                        // 2. بعد العودة مباشرة، اطلب من الـ Cubit تحديث البيانات
                        // fix home screen not updated after recording
                        if (tx != null && context.mounted) {
                          // update local state and prefs in one place
                          context.read<HomeCubit>().addTransaction(tx);
                        }
                      },
                      child: FaIcon(
                        FontAwesomeIcons.microphone,
                        size: 18.sp,
                        color: AppColors.greenColor,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    GestureDetector(
                      onTap: onEditBalance,
                      child: Container(
                        width: 34.w,
                        height: 34.h,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.15)
                              : Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.edit_outlined,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.8)
                              : Colors.black.withOpacity(0.8),
                          size: 16.sp,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // Progress bar
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'home.monthly_limit'.tr(),
                          style: AppText.body12(context).copyWith(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.7)
                                : Colors.black.withOpacity(0.7),
                            fontSize: 11.sp,
                          ),
                        ),
                        Text(
                          '${(spentRatio.clamp(0.0, 1.0) * 100).toStringAsFixed(0)}%',
                          style: AppText.body12(context).copyWith(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.7)
                                : Colors.black.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: LinearProgressIndicator(
                        value: isArabic
                            ? 1.0 - spentRatio.clamp(0.0, 1.0)
                            : spentRatio.clamp(0.0, 1.0),
                        minHeight: 6.h,
                        backgroundColor: AppColors.whiteColor,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          spentRatio > 0.8
                              ? Colors.redAccent
                              : AppColors.greenColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
