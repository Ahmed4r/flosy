import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/home/presentation/screens/detailed_chart_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pie_chart/pie_chart.dart';

Widget buildChart(
  BuildContext context, {
  required double expenses,
  required Map<String, double> categories,
  bool isArabic = false,
}) {
  bool isDarkMode = AppTheme.isDarkMode(context);

  // Check if categories is empty
  if (categories.isEmpty) {
    return SizedBox(
      height: 200.h,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black54 : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isDarkMode ? Colors.white12 : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.8),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pie_chart_outline, size: 48.sp, color: Colors.grey),
              SizedBox(height: 8.h),
              Text(
                'home.no_transactions'.tr(),
                style: AppText.body16(context).copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  final dataMap = categories;

  final total = dataMap.values.fold<double>(0, (sum, val) => sum + val);
  final percentageMap = <String, String>{};
  dataMap.forEach((key, value) {
    final percentage = ((value / total) * 100).toStringAsFixed(1);
    percentageMap[key] = '$percentage%';
  });

  return Container(
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(
      color: isDarkMode ? Colors.black54 : Colors.white,
      borderRadius: BorderRadius.circular(20.r),
      border: Border.all(
        color: isDarkMode ? Colors.white12 : Colors.grey.withOpacity(0.3),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.8),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'home.this_month'.tr(),
              style: AppText.body16(context).copyWith(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            GestureDetector(
              onTap: () {
                // Navigate to detailed chart screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DetailedChartScreen(isArabic: isArabic),
                  ),
                );
              },
              child: Row(
                children: [
                  Text(
                    'home.view_all'.tr(),
                    style: AppText.body12grey(context).copyWith(
                      color: isDarkMode ? Colors.white : Colors.black54,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 8.sp,
                    color: isDarkMode ? Colors.white : AppColors.greyColor,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
  
        // Chart and Legend Row - CONSTRAINED WIDTH
        SizedBox(
          height: 150.h,
          child: Row(
            children: [
              // Pie Chart - FIXED WIDTH
              SizedBox(
                width: 120.w,
                height: 120.h,
                child: PieChart(
                  dataMap: dataMap,
                  animationDuration: Duration(milliseconds: 800),
                  chartRadius: 100.r,
                  colorList: [
                    AppColors.greenColor,
                    Colors.blue,
                    Colors.purple,
                    Colors.orange,
                  ],
                  initialAngleInDegree: 0,
                  chartType: ChartType.ring,
                  ringStrokeWidth: 8,
                  centerWidget: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'home.spent'.tr(),
                        style: AppText.body12grey(context).copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black54,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '\$${expenses.toStringAsFixed(0)}',
                        style: AppText.body16(context).copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  legendOptions: LegendOptions(showLegends: false),
                  chartValuesOptions: ChartValuesOptions(
                    showChartValues: false,
                  ),
                ),
              ),
              SizedBox(width: 16.w),
  
              // Custom Legend - FLEXIBLE
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: dataMap.keys.map((category) {
                      final colors = [
                        AppColors.greenColor,
                        Colors.blue,
                        Colors.purple,
                        Colors.orange,
                      ];
                      final colorIndex = dataMap.keys.toList().indexOf(
                        category,
                      );
  
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Row(
                          children: [
                            Container(
                              width: 12.w,
                              height: 12.w,
                              decoration: BoxDecoration(
                                color: colors[colorIndex],
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                'categories.$category'.tr(),
                                style: AppText.body14(context).copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                            Text(
                              percentageMap[category] ?? '0%',
                              style: AppText.body14(context).copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
