class PredictionModel {
  final String category;
  final double predictedAmount;
  final double currentSpending;
  final double growthRate;
  final DateTime predictedFor;
  final int confidence; // 0-100

  PredictionModel({
    required this.category,
    required this.predictedAmount,
    required this.currentSpending,
    required this.growthRate,
    required this.predictedFor,
    required this.confidence,
  });

  double get difference => predictedAmount - currentSpending;
  bool get isIncreasing => growthRate > 0;
  
  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'predictedAmount': predictedAmount,
      'currentSpending': currentSpending,
      'growthRate': growthRate,
      'predictedFor': predictedFor.millisecondsSinceEpoch,
      'confidence': confidence,
    };
  }

  factory PredictionModel.fromMap(Map<String, dynamic> map) {
    return PredictionModel(
      category: map['category'] as String,
      predictedAmount: (map['predictedAmount'] as num).toDouble(),
      currentSpending: (map['currentSpending'] as num).toDouble(),
      growthRate: (map['growthRate'] as num).toDouble(),
      predictedFor: DateTime.fromMillisecondsSinceEpoch(map['predictedFor'] as int),
      confidence: map['confidence'] as int,
    );
  }
}
