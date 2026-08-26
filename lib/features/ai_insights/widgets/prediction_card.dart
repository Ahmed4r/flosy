import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/features/ai_insights/data/model/prediction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PredictionCard extends StatelessWidget {
  final PredictionModel prediction;

  const PredictionCard({super.key, required this.prediction});

  FaIconData _getCategoryIcon(String category) {
    switch (category) {
      case 'food':
        return FontAwesomeIcons.burger;
      case 'shopping':
        return FontAwesomeIcons.bagShopping;
      case 'transport':
        return FontAwesomeIcons.car;
      case 'fun':
        return FontAwesomeIcons.film;
      case 'rent':
        return FontAwesomeIcons.house;
      case 'health':
        return FontAwesomeIcons.heartPulse;
      default:
        return FontAwesomeIcons.dollarSign;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'food':
        return Colors.orange;
      case 'shopping':
        return Colors.purple;
      case 'transport':
        return Colors.green;
      case 'fun':
        return Colors.red;
      case 'rent':
        return Colors.blue;
      case 'health':
        return Colors.teal;
      default:
        return AppColors.greenColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppTheme.isDarkMode(context);
    final categoryColor = _getCategoryColor(prediction.category);
    final isIncreasing = prediction.isIncreasing;
    final trendColor = isIncreasing ? Colors.red : AppColors.greenColor;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: FaIcon(
                  _getCategoryIcon(prediction.category),
                  color: categoryColor,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'transaction.categories.${prediction.category}'.tr(),
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.speed,
                          size: 12.sp,
                          color: _getConfidenceColor(prediction.confidence),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${prediction.confidence}% ${'ai.confidence'.tr()}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: _getConfidenceColor(prediction.confidence),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: trendColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      isIncreasing
                          ? FontAwesomeIcons.arrowTrendUp
                          : FontAwesomeIcons.arrowTrendDown,
                      color: trendColor,
                      size: 12.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '${prediction.growthRate.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: trendColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Amount Comparison
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? categoryColor.withOpacity(0.08)
                  : categoryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'ai.current'.tr(),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '\$${prediction.currentSpending.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                FaIcon(
                  FontAwesomeIcons.arrowRight,
                  color: categoryColor,
                  size: 18.sp,
                ),
                Column(
                  children: [
                    Text(
                      'ai.predicted'.tr(),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '\$${prediction.predictedAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: categoryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Difference
          if (prediction.difference.abs() > 0.01) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: trendColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    isIncreasing
                        ? FontAwesomeIcons.circleExclamation
                        : FontAwesomeIcons.circleCheck,
                    color: trendColor,
                    size: 14.sp,
                  ),
                  SizedBox(width: 8.w),
                  Flexible(
                    child: Text(
                      isIncreasing
                          ? '${'ai.increase_by'.tr()} \$${prediction.difference.abs().toStringAsFixed(2)}'
                          : '${'ai.decrease_by'.tr()} \$${prediction.difference.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        color: trendColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getConfidenceColor(int confidence) {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.orange;
    return Colors.red;
  }
}
