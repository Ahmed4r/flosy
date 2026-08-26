import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum InsightType { warning, tip, achievement, info }

class InsightModel {
  final String title;
  final String description;
  final InsightType type;
  final FaIconData icon;
  final DateTime createdAt;

  InsightModel({
    required this.title,
    required this.description,
    required this.type,
    required this.icon,
    required this.createdAt,
  });

  Color getColor() {
    switch (type) {
      case InsightType.warning:
        return Colors.orange;
      case InsightType.tip:
        return Colors.blue;
      case InsightType.achievement:
        return Colors.green;
      case InsightType.info:
        return Colors.purple;
    }
  }
}
