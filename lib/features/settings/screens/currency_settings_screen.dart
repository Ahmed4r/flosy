import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/settings/cubit/settings_cubit.dart';
import 'package:flosy/features/settings/domain/currency_metadata.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../cubit/settings_state.dart';

class CurrencySettingsScreen extends StatelessWidget {
  const CurrencySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppTheme.isDarkMode(context);

    // Single centralized source of currency metadata (code, name, symbol,
    // icon). Replaces the old `List<Map<String, dynamic>> currencies`.
    final currencies = CurrencyRegistry.all;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.blackColor : AppColors.whiteColor,
      appBar: AppBar(
        backgroundColor: isDarkMode
            ? AppColors.blackColor
            : AppColors.whiteColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'settings.select_currency'.tr(),
          style: AppText.body16(context).copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          String selectedCurrency = 'EUR'; // Default to EUR if not loaded yet
          if (state is SettingsLoaded) {
            selectedCurrency = state.selectedCurrency;
          }

          return ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: currencies.length,
            separatorBuilder: (context, index) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final currency = currencies[index];
              final isSelected = selectedCurrency == currency.code;

              return GestureDetector(
                onTap: () {
                  context.read<SettingsCubit>().changeCurrency(currency.code);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('settings.currency_changed'.tr()),
                      backgroundColor: AppColors.greenColor,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.greenColor.withOpacity(0.1)
                        : (isDarkMode ? Colors.black54 : Colors.white),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.greenColor
                          : (isDarkMode
                                ? Colors.white12
                                : Colors.grey.withOpacity(0.3)),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.greenColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48.w,
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.greenColor
                              : (isDarkMode
                                    ? Colors.white12
                                    : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Center(
                          // No `as FaIconData` cast — currency.icon is
                          // already a typed FaIconData from the registry.
                          child: FaIcon(
                            currency.icon,
                            color: isSelected
                                ? Colors.white
                                : (isDarkMode
                                      ? Colors.white70
                                      : Colors.grey[700]),
                            size: 24.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${currency.code} - ${currency.displayName}',
                              style: AppText.body16(context).copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '${'settings.symbol'.tr()} ${currency.symbol}',
                              style: AppText.body14(context).copyWith(
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: AppColors.greenColor,
                          size: 24.sp,
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
