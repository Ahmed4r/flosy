import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ml_interpreter_stub.dart'
    if (dart.library.io) 'ml_interpreter_io.dart'
    as ml_interpreter;

class MLPredictionService {
  static final MLPredictionService _instance = MLPredictionService._internal();
  factory MLPredictionService() => _instance;
  MLPredictionService._internal();

  dynamic _interpreter;
  List<double>? _mean;
  List<double>? _std;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  bool get _isMlSupportedPlatform => !kIsWeb;

  /// Initialize the TFLite model and normalization parameters
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (!_isMlSupportedPlatform) {
        _isInitialized = true;
        developer.log('ML prediction skipped on web platform');
        return;
      }
      WidgetsFlutterBinding.ensureInitialized(); // ADD THIS LINE

      // Load the TFLite model
      _interpreter = await ml_interpreter.createInterpreterFromAsset(
        'assets/models/expense_predictor.tflite',
      );
      developer.log(' TFLite model loaded successfully');

      // Load normalization parameters
      final normParamsString = await rootBundle.loadString(
        'assets/models/norm_params.json',
      );
      final normParams = json.decode(normParamsString);
      _mean = List<double>.from(normParams['mean']);
      _std = List<double>.from(normParams['std']);
      developer.log(' Normalization parameters loaded');

      _isInitialized = true;
    } catch (e) {
      developer.log(' Error initializing ML model: $e');
      _isInitialized = false;
    }
  }

  /// Predict next month's expense
  ///
  /// Parameters:
  /// - lastMonthExpense: Spending in the last month
  /// - twoMonthsAgo: Spending two months ago
  /// - avgThreeMonths: Average spending over 3 months
  /// - monthNumber: Current month (1-12)
  /// - dayOfMonth: Current day of month (1-31)
  ///
  /// Returns: Predicted expense for next month
  Future<double> predictExpense({
    required double lastMonthExpense,
    required double twoMonthsAgo,
    required double avgThreeMonths,
    required int monthNumber,
    required int dayOfMonth,
  }) async {
    if (!_isMlSupportedPlatform) {
      // Web fallback: skip TFLite inference and use recent trend average.
      return avgThreeMonths;
    }

    if (!_isInitialized) {
      throw Exception('ML model not initialized. Call initialize() first.');
    }

    if (_interpreter == null || _mean == null || _std == null) {
      throw Exception('Model or normalization parameters not loaded');
    }

    try {
      // Prepare input features
      final features = [
        lastMonthExpense,
        twoMonthsAgo,
        avgThreeMonths,
        monthNumber.toDouble(),
        dayOfMonth.toDouble(),
      ];

      // Normalize input using loaded parameters
      final normalizedFeatures = <double>[];
      for (int i = 0; i < features.length; i++) {
        final normalized = (features[i] - _mean![i]) / (_std![i] + 1e-8);
        normalizedFeatures.add(normalized);
      }

      // Prepare input tensor
      final input = [normalizedFeatures];

      // Prepare output tensor
      final output = List.generate(1, (_) => List.filled(1, 0.0));

      // Run inference
      _interpreter.run(input, output);

      // Get prediction
      final prediction = output[0][0];

      print(' ML Prediction: \$${prediction.toStringAsFixed(2)}');

      // Ensure prediction is positive
      return prediction.abs();
    } catch (e) {
      print(' Error making prediction: $e');
      // Fallback to simple average if ML fails
      return avgThreeMonths;
    }
  }

  /// Batch predict for multiple categories
  Future<Map<String, double>> predictMultipleCategories(
    Map<String, Map<String, double>> categoryData,
  ) async {
    final predictions = <String, double>{};

    for (var entry in categoryData.entries) {
      final category = entry.key;
      final data = entry.value;

      try {
        final prediction = await predictExpense(
          lastMonthExpense: data['lastMonth'] ?? 0.0,
          twoMonthsAgo: data['twoMonthsAgo'] ?? 0.0,
          avgThreeMonths: data['avg3Months'] ?? 0.0,
          monthNumber: DateTime.now().month,
          dayOfMonth: DateTime.now().day,
        );

        predictions[category] = prediction;
      } catch (e) {
        print('Error predicting for $category: $e');
        predictions[category] = data['avg3Months'] ?? 0.0;
      }
    }

    return predictions;
  }

  /// Calculate confidence score based on data consistency
  int calculateConfidence({
    required double lastMonth,
    required double twoMonthsAgo,
    required double threeMonthsAgo,
  }) {
    if (lastMonth == 0 && twoMonthsAgo == 0 && threeMonthsAgo == 0) {
      return 0;
    }

    final values = [
      lastMonth,
      twoMonthsAgo,
      threeMonthsAgo,
    ].where((v) => v > 0).toList();

    if (values.isEmpty) return 0;
    if (values.length == 1) return 50;

    // Calculate coefficient of variation
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
        values.length;
    final stdDev = sqrt(variance);
    final cv = (stdDev / mean) * 100;

    // Convert CV to confidence score (lower CV = higher confidence)
    if (cv < 10) return 95;
    if (cv < 20) return 85;
    if (cv < 30) return 75;
    if (cv < 40) return 65;
    if (cv < 50) return 55;
    return 50;
  }

  /// Dispose resources
  void dispose() {
    ml_interpreter.closeInterpreter(_interpreter);
    _interpreter = null;
    _isInitialized = false;
    print(' ML model disposed');
  }
}

// Global instance
final mlService = MLPredictionService();
