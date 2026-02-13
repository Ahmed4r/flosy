import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flosy/features/ai_insights/data/model/insight_model.dart';
import 'package:flosy/features/ai_insights/data/model/prediction_model.dart';
import 'package:flosy/features/ai_insights/services/ml_prediction_service.dart';
import 'package:flosy/features/home/data/model/transaction_model.dart';
import 'package:flosy/features/home/presentation/services/db.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

part 'ai_insights_state.dart';

class AiInsightsCubit extends Cubit<AiInsightsState> {
  AiInsightsCubit() : super(AiInsightsInitial());

  Future<void> generateInsights() async {
    emit(AiInsightsLoading());

    try {
      if (!mlService.isInitialized) {
        await mlService.initialize();
      }

      final transactions = await dbService.getTransactions();

      if (transactions.isEmpty) {
        emit(AiInsightsEmpty());
        return;
      }

      final predictions = await _generateMLPredictions(transactions);
      final insights = _generateInsights(transactions, predictions);
      final metrics = _calculateMetrics(transactions, predictions);

      emit(
        AiInsightsLoaded(
          predictions: predictions,
          insights: insights,
          totalPredicted: metrics['totalPredicted']!,
          potentialSavings: metrics['potentialSavings']!,
          riskScore: metrics['riskScore']!,
        ),
      );
    } catch (e) {
      emit(AiInsightsError('Failed to generate insights: ${e.toString()}'));
    }
  }

  Future<List<PredictionModel>> _generateMLPredictions(
    List<TransactionModel> transactions,
  ) async {
    final now = DateTime.now();
    final categories = [
      'food',
      'shopping',
      'transport',
      'fun',
      'rent',
      'health',
    ];
    final predictions = <PredictionModel>[];

    for (var category in categories) {
      final lastMonthSpending = _getMonthlySpending(
        transactions,
        category,
        DateTime(now.year, now.month - 1),
      );

      final twoMonthsAgoSpending = _getMonthlySpending(
        transactions,
        category,
        DateTime(now.year, now.month - 2),
      );

      final threeMonthsAgoSpending = _getMonthlySpending(
        transactions,
        category,
        DateTime(now.year, now.month - 3),
      );

      if (lastMonthSpending == 0 &&
          twoMonthsAgoSpending == 0 &&
          threeMonthsAgoSpending == 0) {
        continue;
      }

      final avgThreeMonths =
          (lastMonthSpending + twoMonthsAgoSpending + threeMonthsAgoSpending) /
          3;

      double predictedAmount;
      try {
        predictedAmount = await mlService.predictExpense(
          lastMonthExpense: lastMonthSpending,
          twoMonthsAgo: twoMonthsAgoSpending,
          avgThreeMonths: avgThreeMonths,
          monthNumber: now.month,
          dayOfMonth: now.day,
        );
      } catch (e) {
        predictedAmount = avgThreeMonths;
      }

      final growthRate = twoMonthsAgoSpending > 0
          ? ((lastMonthSpending - twoMonthsAgoSpending) /
                    twoMonthsAgoSpending) *
                100
          : 0.0;

      final confidence = mlService.calculateConfidence(
        lastMonth: lastMonthSpending,
        twoMonthsAgo: twoMonthsAgoSpending,
        threeMonthsAgo: threeMonthsAgoSpending,
      );

      predictions.add(
        PredictionModel(
          category: category,
          predictedAmount: predictedAmount,
          currentSpending: lastMonthSpending,
          growthRate: growthRate,
          predictedFor: DateTime(now.year, now.month + 1),
          confidence: confidence,
        ),
      );
    }

    return predictions;
  }

  double _getMonthlySpending(
    List<TransactionModel> transactions,
    String category,
    DateTime targetMonth,
  ) {
    return transactions
        .where(
          (t) =>
              t.category == category &&
              t.type == TransactionType.expense &&
              t.date.year == targetMonth.year &&
              t.date.month == targetMonth.month,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  List<InsightModel> _generateInsights(
    List<TransactionModel> transactions,
    List<PredictionModel> predictions,
  ) {
    final insights = <InsightModel>[];

    // ML-powered insight
    insights.add(
      InsightModel(
        title: 'ai.ai_active'.tr(),
        description: 'ai.ai_active_desc'.tr(
          args: [transactions.length.toString()],
        ),
        type: InsightType.info,
        icon: FontAwesomeIcons.microchip,
        createdAt: DateTime.now(),
      ),
    );

    // High growth categories
    for (var prediction in predictions) {
      if (prediction.growthRate > 20) {
        insights.add(
          InsightModel(
            title: 'ai.high_growth_alert'.tr(),
            description: 'ai.high_growth_desc'.tr(
              args: [
                'transaction.categories.${prediction.category}'.tr(),
                prediction.growthRate.toStringAsFixed(1),
              ],
            ),
            type: InsightType.warning,
            icon: FontAwesomeIcons.triangleExclamation,
            createdAt: DateTime.now(),
          ),
        );
      }
    }

    // High confidence predictions
    final highConfidence = predictions
        .where((p) => p.confidence >= 85)
        .toList();
    if (highConfidence.isNotEmpty) {
      insights.add(
        InsightModel(
          title: 'ai.high_confidence'.tr(),
          description: 'ai.high_confidence_desc'.tr(
            args: [highConfidence.length.toString()],
          ),
          type: InsightType.achievement,
          icon: FontAwesomeIcons.chartLine,
          createdAt: DateTime.now(),
        ),
      );
    }

    // Savings opportunities
    final sortedPredictions = List<PredictionModel>.from(predictions)
      ..sort((a, b) => b.predictedAmount.compareTo(a.predictedAmount));

    if (sortedPredictions.isNotEmpty) {
      final highest = sortedPredictions.first;
      insights.add(
        InsightModel(
          title: 'ai.smart_savings'.tr(),
          description: 'ai.smart_savings_desc'.tr(
            args: [
              'transaction.categories.${highest.category}'.tr(),
              (highest.predictedAmount * 0.15).toStringAsFixed(2),
            ],
          ),
          type: InsightType.tip,
          icon: FontAwesomeIcons.piggyBank,
          createdAt: DateTime.now(),
        ),
      );
    }

    // Stable spending achievement
    final stableCategories = predictions
        .where((p) => p.growthRate.abs() < 5 && p.currentSpending > 0)
        .length;

    if (stableCategories >= 3) {
      insights.add(
        InsightModel(
          title: 'ai.great_control'.tr(),
          description: 'ai.great_control_desc'.tr(
            args: [stableCategories.toString()],
          ),
          type: InsightType.achievement,
          icon: FontAwesomeIcons.trophy,
          createdAt: DateTime.now(),
        ),
      );
    }

    return insights;
  }

  Map<String, double> _calculateMetrics(
    List<TransactionModel> transactions,
    List<PredictionModel> predictions,
  ) {
    final totalPredicted = predictions.fold(
      0.0,
      (sum, p) => sum + p.predictedAmount,
    );

    final sortedPredictions = List<PredictionModel>.from(predictions)
      ..sort((a, b) => b.predictedAmount.compareTo(a.predictedAmount));

    final potentialSavings = sortedPredictions.isNotEmpty
        ? sortedPredictions.first.predictedAmount * 0.15
        : 0.0;

    final avgGrowthRate = predictions.isNotEmpty
        ? predictions.fold(0.0, (sum, p) => sum + p.growthRate) /
              predictions.length
        : 0.0;

    final riskScore = (avgGrowthRate + 50).clamp(0, 100).toDouble();

    return {
      'totalPredicted': totalPredicted,
      'potentialSavings': potentialSavings,
      'riskScore': riskScore,
    };
  }

  // Add to AiInsightsCubit for testing - REMOVE LATER
  Future<void> testWithFakeData() async {
    emit(AiInsightsLoading());

    try {
      if (!mlService.isInitialized) {
        await mlService.initialize();
      }

      final prediction = await mlService.predictExpense(
        lastMonthExpense: 500.0,
        twoMonthsAgo: 450.0,
        avgThreeMonths: 470.0,
        monthNumber: DateTime.now().month,
        dayOfMonth: DateTime.now().day,
      );

      log('Test prediction result: \$$prediction');

      final confidence = mlService.calculateConfidence(
        lastMonth: 500.0,
        twoMonthsAgo: 450.0,
        threeMonthsAgo: 460.0,
      );

      print('Confidence: $confidence%');

      // Emit loaded state with test data
      emit(
        AiInsightsLoaded(
          predictions: [
            PredictionModel(
              category: 'food',
              predictedAmount: prediction,
              currentSpending: 500.0,
              growthRate: 11.1,
              predictedFor: DateTime.now(),
              confidence: confidence,
            ),
          ],
          insights: [
            InsightModel(
              title: 'ai.ai_active'.tr(),
              description: 'ai.ai_active_desc'.tr(args: ['50']),
              type: InsightType.info,
              icon: FontAwesomeIcons.microchip,
              createdAt: DateTime.now(),
            ),
          ],
          totalPredicted: prediction,
          potentialSavings: prediction * 0.15,
          riskScore: 60.0,
        ),
      );
    } catch (e) {
      print('Test failed: $e');
      emit(AiInsightsError(e.toString()));
    }
  }
}
