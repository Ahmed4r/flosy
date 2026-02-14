import 'package:flutter/widgets.dart';

class TransactionModel {
  int? id;
  final String title;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String category;

  /// Store icon as data, not IconData itself
  final int iconCodePoint;
  final String iconFontFamily;
  final String? iconFontPackage; // <-- new

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    required this.category,
    required this.iconCodePoint,
    required this.iconFontFamily,
    this.iconFontPackage, // <-- new
  });

  /// Convenience getter for UI
  IconData get icon => IconData(
    iconCodePoint,
    fontFamily: iconFontFamily,
    fontPackage: iconFontPackage, // <-- important for FontAwesome
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.index,
      'date': date.millisecondsSinceEpoch,
      'category': category,
      'iconCodePoint': iconCodePoint,
      'iconFontFamily': iconFontFamily,
      'iconFontPackage': iconFontPackage, // <-- new
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values[map['type'] as int],
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      category: map['category'] as String,
      iconCodePoint: map['iconCodePoint'] as int,
      iconFontFamily: map['iconFontFamily'] as String,
      iconFontPackage: map['iconFontPackage'] as String?, // <-- new
     
    );
  }
}

enum TransactionType { income, expense, savings }
