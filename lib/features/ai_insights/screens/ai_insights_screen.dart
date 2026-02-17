import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/core/utils/app_colors.dart';
import 'package:flosy/features/ai_insights/cubit/ai_insights_cubit.dart';
import 'package:flosy/features/ai_insights/services/ml_prediction_service.dart';
import 'package:flosy/features/ai_insights/widgets/insight_card.dart';
import 'package:flosy/features/ai_insights/widgets/metrics_card.dart';
import 'package:flosy/features/ai_insights/widgets/prediction_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AiInsightsScreen extends StatefulWidget {
  const AiInsightsScreen({super.key});

  @override
  State<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends State<AiInsightsScreen> {
  @override
  void initState() {
    super.initState();
    mlService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // create: (context) => AiInsightsCubit()..generateInsights(),
      create: (context) => AiInsightsCubit()..generateInsights(),
      child: const _AiInsightsView(),
    );
  }
}

class _AiInsightsView extends StatelessWidget {
  const _AiInsightsView();

  Color get _bgColor =>
      _isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5);

  Color get _cardColor => _isDark ? const Color(0xFF1A1A1A) : Colors.white;

  Color get _textPrimary => _isDark ? Colors.white : Colors.black;

  // Will be set each build call
  static bool _isDark = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AppTheme.isDarkMode(context);
    _isDark = isDarkMode;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDarkMode),
            Expanded(
              child: BlocBuilder<AiInsightsCubit, AiInsightsState>(
                builder: (context, state) {
                  if (state is AiInsightsLoading) {
                    return _buildLoading(context, isDarkMode);
                  }
                  if (state is AiInsightsEmpty) {
                    return _buildEmpty(context, isDarkMode);
                  }
                  if (state is AiInsightsError) {
                    return _buildError(context, isDarkMode, state.message);
                  }
                  if (state is AiInsightsLoaded) {
                    return _buildContent(context, isDarkMode, state);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  if (!isDarkMode)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 18.sp,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Image.asset(
              'assets/icons/ai.png',

              width: 21.w,
              height: 21.h,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'ai.title'.tr(),
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.w800,
                color: isDarkMode ? Colors.white : Colors.black,
                letterSpacing: -0.5,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              context.read<AiInsightsCubit>().generateInsights();
            },
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  if (!isDarkMode)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: FaIcon(
                FontAwesomeIcons.arrowsRotate,
                color: AppColors.greenColor,
                size: 18.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(BuildContext context, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.greenColor),
          SizedBox(height: 16.h),
          Text(
            'ai.analyzing'.tr(),
            style: TextStyle(
              fontSize: 14.sp,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, bool isDarkMode) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
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
              child: FaIcon(
                FontAwesomeIcons.chartLine,
                size: 48.sp,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'ai.no_data'.tr(),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'ai.no_data_desc'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, bool isDarkMode, String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: FaIcon(
                FontAwesomeIcons.triangleExclamation,
                size: 48.sp,
                color: Colors.red[400],
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'ai.error'.tr(),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    bool isDarkMode,
    AiInsightsLoaded state,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<AiInsightsCubit>().generateInsights();
      },
      color: AppColors.greenColor,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8.h),

            // Metrics Cards
            Row(
              children: [
                Expanded(
                  child: MetricsCard(
                    title: 'ai.predicted_total'.tr(),
                    value: '\$${state.totalPredicted.toStringAsFixed(2)}',
                    icon: FontAwesomeIcons.arrowTrendUp,
                    color: Colors.blue,
                    isDarkMode: isDarkMode,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: MetricsCard(
                    title: 'ai.potential_savings'.tr(),
                    value: '\$${state.potentialSavings.toStringAsFixed(2)}',
                    icon: FontAwesomeIcons.piggyBank,
                    color: AppColors.greenColor,
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
            SizedBox(height: 28.h),

            // Insights Section
            _buildSectionLabel('ai.insights'.tr()),
            SizedBox(height: 12.h),
            ...state.insights.map(
              (insight) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: InsightCard(insight: insight),
              ),
            ),
            SizedBox(height: 28.h),

            // Predictions Section
            _buildSectionLabel('ai.predictions'.tr()),
            SizedBox(height: 12.h),
            ...state.predictions.map(
              (prediction) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: PredictionCard(prediction: prediction),
              ),
            ),
            SizedBox(height: 16.h),
            Center(
              child: Text(
                'ai.powered_by'.tr(),
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11.sp,
        color: Colors.grey[500],
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }
}
