import 'package:flutter/widgets.dart';

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String category;
  final IconData icon;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    required this.category,
    required this.icon,
  });
}

enum TransactionType { income, expense, savings }