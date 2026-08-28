import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  IconData get icon {
    if (iconCodePoint == 0) {
      return Icons.help_outline;
    }

    return IconData(
      iconCodePoint,
      fontFamily: iconFontFamily.isNotEmpty ? iconFontFamily : 'MaterialIcons',
      fontPackage: iconFontPackage,
    );
  }

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
      period: map['period'] as String? ?? 'monthly',
      startDate: map['startDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startDate'] as int)
          : DateTime.now(),
      endDate: map['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endDate'] as int)
          : DateTime.now(),
      // iconCodePoint / iconFontFamily may be NULL in old DB rows —
      // fall back to safe defaults so fromMap never crashes.
      iconCodePoint: (map['iconCodePoint'] as int?) ?? 0,
      iconFontFamily: (map['iconFontFamily'] as String?) ?? 'MaterialIcons',
      iconFontPackage: map['iconFontPackage'] as String?,
      notifyAtThreshold: ((map['notifyAtThreshold'] as int?) ?? 1) == 1,
      notifyPercent: (map['notifyPercent'] as num?)?.toDouble() ?? 80,
      isRecurring: ((map['isRecurring'] as int?) ?? 1) == 1,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
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
