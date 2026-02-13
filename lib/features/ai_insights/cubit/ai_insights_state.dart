part of 'ai_insights_cubit.dart';

abstract class AiInsightsState {}

class AiInsightsInitial extends AiInsightsState {}

class AiInsightsLoading extends AiInsightsState {}

class AiInsightsEmpty extends AiInsightsState {}

class AiInsightsLoaded extends AiInsightsState {
  final List<PredictionModel> predictions;
  final List<InsightModel> insights;
  final double totalPredicted;
  final double potentialSavings;
  final double riskScore;

  AiInsightsLoaded({
    required this.predictions,
    required this.insights,
    required this.totalPredicted,
    required this.potentialSavings,
    required this.riskScore,
  });
}

class AiInsightsError extends AiInsightsState {
  final String message;

  AiInsightsError(this.message);
}
