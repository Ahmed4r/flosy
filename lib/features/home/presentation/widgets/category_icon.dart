// lib/features/home/presentation/widgets/category_icon.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'category_metadata.dart';

/// Renders the correct icon widget (Icon vs FaIcon) for a category id,
/// resolved via [CategoryRegistry]. Callers only ever pass a category id
/// string (or a [CategoryMetadata] if already resolved) — never an icon.
class CategoryIcon extends StatelessWidget {
  final String categoryId;
  final double size;
  final Color? colorOverride;

  const CategoryIcon({
    super.key,
    required this.categoryId,
    this.size = 28,
    this.colorOverride,
  });

  @override
  Widget build(BuildContext context) {
    final meta = CategoryRegistry.resolveById(categoryId);
    final color = colorOverride ?? meta.color;

    switch (meta.iconKind) {
      case CategoryIconKind.material:
        return Icon(meta.materialIcon, color: color, size: size);
      case CategoryIconKind.fontAwesome:
        return FaIcon(meta.faIcon, color: color, size: size);
    }
  }
}