import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/core/utils/app_text.dart';
import 'package:flosy/features/home/presentation/screens/detailed_chart_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pie_chart/pie_chart.dart';

// Dynamic color map matching TransactionColors
const Map<String, Color> _categoryColors = {
  'food': Colors.orange,
  'rent': Colors.blue,
  'transport': Colors.green,
  'shopping': Colors.purple,
  'fun': Colors.red,
  'health': Colors.teal,
  'salary': Colors.indigo,
  'bills': Colors.amber,
  'more': Colors.grey,
};

Color _getCategoryColor(String category, int fallbackIndex) {
  return _categoryColors[category] ??
      [
        AppColors.greenColor,
        Colors.blue,
        Colors.purple,
        Colors.orange,
        Colors.teal,
        Colors.pink,
        Colors.amber,
        Colors.cyan,
      ][fallbackIndex % 8];
}

Widget buildChart(
  BuildContext context, {
  required double expenses,
  required Map<String, double> categories,
  bool isArabic = false,
}) {
  bool isDarkMode = AppTheme.isDarkMode(context);

  if (categories.isEmpty) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 16.w),
      decoration: _cardDecoration(isDarkMode),
      child: Column(
        children: [
          Container(
            width: 64.w,
            height: 64.h,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pie_chart_outline,
              size: 32.sp,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'home.no_transactions'.tr(),
            style: AppText.body16(
              context,
            ).copyWith(color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 4.h),
          Text(
            'Add expenses to see your chart',
            style: AppText.body12(context).copyWith(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  final dataMap = categories;
  final total = dataMap.values.fold<double>(0, (sum, val) => sum + val);

  // Build color list matching category order
  final colorList = <Color>[];
  int i = 0;
  for (final key in dataMap.keys) {
    colorList.add(_getCategoryColor(key, i));
    i++;
  }

  return Container(
    padding: EdgeInsets.all(20.w),
    decoration: _cardDecoration(isDarkMode),
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
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailedChartScreen(isArabic: isArabic),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'home.view_all'.tr(),
                      style: AppText.body12(context).copyWith(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10.sp,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),

        // Chart + Legend
        SizedBox(
          height: 140.h,
          child: Row(
            children: [
              // Pie Chart
              SizedBox(
                width: 130.w,
                height: 130.h,
                child: PieChart(
                  dataMap: dataMap,
                  animationDuration: const Duration(milliseconds: 1000),
                  chartRadius: 110.r,
                  colorList: colorList,
                  initialAngleInDegree: -90,
                  chartType: ChartType.ring,
                  ringStrokeWidth: 10,
                  centerWidget: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'home.spent'.tr(),
                        style: AppText.body12(context).copyWith(
                          color: isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '\$${expenses.toStringAsFixed(0)}',
                        style: AppText.body18(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  legendOptions: const LegendOptions(showLegends: false),
                  chartValuesOptions: const ChartValuesOptions(
                    showChartValues: false,
                  ),
                ),
              ),
              SizedBox(width: 20.w),

              // Legend
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(dataMap.length, (index) {
                      final key = dataMap.keys.elementAt(index);
                      final value = dataMap[key]!;
                      final pct = ((value / total) * 100).toStringAsFixed(1);

                      return Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: Row(
                          children: [
                            Container(
                              width: 10.w,
                              height: 10.w,
                              decoration: BoxDecoration(
                                color: colorList[index],
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                'categories.$key'.tr(),
                                style: AppText.body14(context).copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '$pct%',
                              style: AppText.body14(context).copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
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

BoxDecoration _cardDecoration(bool isDarkMode) {
  return BoxDecoration(
    color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
    borderRadius: BorderRadius.circular(20.r),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
