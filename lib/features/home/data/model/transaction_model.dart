// lib/features/home/data/model/transaction_model.dart
//
// Domain/data model. Deliberately has NO Flutter import and NO icon
// fields — icon resolution lives entirely in the presentation layer
// (see: transaction_category.dart, category_metadata.dart, category_icon.dart).
//
// category is a plain String id (e.g. "food"). Use
// TransactionCategory.fromId(category) / CategoryRegistry.resolveById(category)
// wherever you need to render it.

class TransactionModel {
  int? id;
  final String title;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String category;
  final String? createdBy;
  final int? colorValue;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    required this.category,
    this.createdBy,
    this.colorValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.index,
      'date': date.millisecondsSinceEpoch,
      'category': category,
      if (createdBy != null) 'createdBy': createdBy,
      if (colorValue != null) 'colorValue': colorValue,
    };
  }

  /// Backward compatible with old SQLite rows / Firestore docs that may
  /// still contain iconCodePoint / iconFontFamily / iconFontPackage —
  /// those keys are simply never read here, so their presence is harmless.
  ///
  /// Also tolerant of a missing/unknown category string: it's kept as-is
  /// (falls back to 'more' only if truly absent), and CategoryRegistry
  /// handles rendering a generic icon for anything it doesn't recognize.
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values[map['type'] as int],
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      category: (map['category'] as String?) ?? 'more',
      createdBy: map['createdBy'] as String?,
      colorValue: map['colorValue'] as int?,
    );
  }
}

enum TransactionType { income, expense, savings }