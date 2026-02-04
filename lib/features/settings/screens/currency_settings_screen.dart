import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/settings/cubit/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CurrencySettingsScreen extends StatelessWidget {
  const CurrencySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppTheme.isDarkMode(context);

    final currencies = [
      {
        'code': 'USD',
        'name': 'US Dollar',
        'symbol': '\$',
        'icon': FontAwesomeIcons.dollarSign,
      },
      {
        'code': 'EUR',
        'name': 'Euro',
        'symbol': '€',
        'icon': FontAwesomeIcons.euroSign,
      },
      {
        'code': 'GBP',
        'name': 'British Pound',
        'symbol': '£',
        'icon': FontAwesomeIcons.sterlingSign,
      },
      {
        'code': 'EGP',
        'name': 'Egyptian Pound',
        'symbol': 'E£',
        'icon': FontAwesomeIcons.moneyBill,
      },
      {
        'code': 'SAR',
        'name': 'Saudi Riyal',
        'symbol': 'SR',
        'icon': FontAwesomeIcons.moneyBill1,
      },
      {
        'code': 'AED',
        'name': 'UAE Dirham',
        'symbol': 'AED',
        'icon': FontAwesomeIcons.coins,
      },
      {
        'code': 'JPY',
        'name': 'Japanese Yen',
        'symbol': '¥',
        'icon': FontAwesomeIcons.yenSign,
      },
      {
        'code': 'CNY',
        'name': 'Chinese Yuan',
        'symbol': '¥',
        'icon': FontAwesomeIcons.yenSign,
      },
    ];

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
          String selectedCurrency = 'USD';
          if (state is SettingsLoaded) {
            selectedCurrency = state.selectedCurrency;
          }

          return ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: currencies.length,
            separatorBuilder: (context, index) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final currency = currencies[index];
              final isSelected = selectedCurrency == currency['code'];

              return GestureDetector(
                onTap: () {
                  // Change currency using the cubit
                  context.read<SettingsCubit>().changeCurrency(
                    currency['code'] as String,
                  );

                  // Show success message
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
                          child: FaIcon(
                            currency['icon'] as IconData,
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
                              '${currency['code']} - ${currency['name']}',
                              style: AppText.body16(context).copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Symbol: ${currency['symbol']}',
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
