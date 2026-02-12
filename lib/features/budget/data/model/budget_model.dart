import 'package:flutter/widgets.dart';

class BudgetModel {
  int? id;
  final String category;
  final double limitAmount;
  final String period;
  final DateTime startDate;
  final DateTime endDate;
  final int iconCodePoint;
  final String iconFontFamily;
  final String? iconFontPackage;
  final bool notifyAtThreshold;
  final double notifyPercent;
  final bool isRecurring;
  final DateTime createdAt;

  BudgetModel({
    this.id,
    required this.category,
    required this.limitAmount,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.iconCodePoint,
    required this.iconFontFamily,
    this.iconFontPackage,
    this.notifyAtThreshold = true,
    this.notifyPercent = 80,
    this.isRecurring = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  IconData get icon => IconData(
    iconCodePoint,
    fontFamily: iconFontFamily,
    fontPackage: iconFontPackage,
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'limitAmount': limitAmount,
      'period': period,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'iconCodePoint': iconCodePoint,
      'iconFontFamily': iconFontFamily,
      'iconFontPackage': iconFontPackage,
      'notifyAtThreshold': notifyAtThreshold ? 1 : 0,
      'notifyPercent': notifyPercent,
      'isRecurring': isRecurring ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as int?,
      category: map['category'] as String,
      limitAmount: (map['limitAmount'] as num).toDouble(),
      period: map['period'] as String,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] as int),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate'] as int),
      iconCodePoint: map['iconCodePoint'] as int,
      iconFontFamily: map['iconFontFamily'] as String,
      iconFontPackage: map['iconFontPackage'] as String?,
      notifyAtThreshold: (map['notifyAtThreshold'] as int) == 1,
      notifyPercent: (map['notifyPercent'] as num?)?.toDouble() ?? 80,
      isRecurring: (map['isRecurring'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  BudgetModel copyWith({
    int? id,
    String? category,
    double? limitAmount,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    int? iconCodePoint,
    String? iconFontFamily,
    String? iconFontPackage,
    bool? notifyAtThreshold,
    double? notifyPercent,
    bool? isRecurring,
    DateTime? createdAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      iconFontPackage: iconFontPackage ?? this.iconFontPackage,
      notifyAtThreshold: notifyAtThreshold ?? this.notifyAtThreshold,
      notifyPercent: notifyPercent ?? this.notifyPercent,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
