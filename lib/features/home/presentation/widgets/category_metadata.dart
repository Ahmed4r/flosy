// lib/features/home/presentation/category/category_metadata.dart
//
// Presentation-layer only. Maps a TransactionCategory -> icon/color/label.
// Nothing in here is persisted; the database only ever stores
// TransactionCategory.id (a String).

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'transaction_category.dart';

/// Distinguishes which widget must render the icon.
/// FaIconData and IconData are NOT interchangeable (this was the
/// root cause of the original crash: FaIconData was being cast
/// `as IconData`, which works on some platforms/versions by luck
/// and throws on Web).
enum CategoryIconKind { material, fontAwesome }

class CategoryMetadata {
  final TransactionCategory category;
  final String labelKey; // easy_localization key, e.g. "categories.food"
  final CategoryIconKind iconKind;
  final IconData? materialIcon; // set iff iconKind == material
  final FaIconData? faIcon; // set iff iconKind == fontAwesome
  final Color color;

  const CategoryMetadata({
    required this.category,
    required this.labelKey,
    required this.iconKind,
    required this.color,
    this.materialIcon,
    this.faIcon,
  }) : assert(
         (iconKind == CategoryIconKind.material && materialIcon != null) ||
             (iconKind == CategoryIconKind.fontAwesome && faIcon != null),
         'Provide the icon matching iconKind',
       );
}

/// Single source of truth for category presentation data.
/// Add a new category by adding one entry here — nothing else in the
/// app needs to know whether its icon is Material or FontAwesome.
class CategoryRegistry {
  CategoryRegistry._();

  static final Map<TransactionCategory, CategoryMetadata> _registry = {
    TransactionCategory.food: const CategoryMetadata(
      category: TransactionCategory.food,
      labelKey: 'categories.food',
      iconKind: CategoryIconKind.fontAwesome,
      faIcon: FontAwesomeIcons.burger,
      color: Colors.orange,
    ),
    TransactionCategory.rent: const CategoryMetadata(
      category: TransactionCategory.rent,
      labelKey: 'categories.rent',
      iconKind: CategoryIconKind.fontAwesome,
      faIcon: FontAwesomeIcons.house,
      color: Colors.blue,
    ),
    TransactionCategory.transport: const CategoryMetadata(
      category: TransactionCategory.transport,
      labelKey: 'categories.transport',
      iconKind: CategoryIconKind.fontAwesome,
      faIcon: FontAwesomeIcons.car,
      color: Colors.green,
    ),
    TransactionCategory.shopping: const CategoryMetadata(
      category: TransactionCategory.shopping,
      labelKey: 'categories.shopping',
      iconKind: CategoryIconKind.fontAwesome,
      faIcon: FontAwesomeIcons.shoppingBag,
      color: Colors.purple,
    ),
    TransactionCategory.fun: const CategoryMetadata(
      category: TransactionCategory.fun,
      labelKey: 'categories.fun',
      iconKind: CategoryIconKind.fontAwesome,
      faIcon: FontAwesomeIcons.film,
      color: Colors.red,
    ),
    TransactionCategory.health: const CategoryMetadata(
      category: TransactionCategory.health,
      labelKey: 'categories.health',
      iconKind: CategoryIconKind.fontAwesome,
      faIcon: FontAwesomeIcons.heartPulse,
      color: Colors.teal,
    ),
    TransactionCategory.salary: const CategoryMetadata(
      category: TransactionCategory.salary,
      labelKey: 'categories.salary',
      iconKind: CategoryIconKind.material,
      materialIcon: Icons.attach_money,
      color: Colors.indigo,
    ),
    TransactionCategory.more: const CategoryMetadata(
      category: TransactionCategory.more,
      labelKey: 'categories.more',
      iconKind: CategoryIconKind.material,
      materialIcon: Icons.more_horiz,
      color: Colors.grey,
    ),
  };

  /// Fallback used for unknown/legacy category strings (requirement 11).
  static const CategoryMetadata _fallback = CategoryMetadata(
    category: TransactionCategory.unknown,
    labelKey: 'categories.unknown',
    iconKind: CategoryIconKind.material,
    materialIcon: Icons.category_outlined,
    color: Colors.grey,
  );

  /// All categories in stable display order (drives the grid).
  static List<CategoryMetadata> get all => _registry.values.toList();

  /// Resolve directly from the raw string id stored in the DB/Firestore.
  /// Never throws; unknown ids resolve to [_fallback] and the caller can
  /// still display the original raw id as the label if desired.
  static CategoryMetadata resolveById(String? id) {
    final category = TransactionCategory.fromId(id);
    return _registry[category] ?? _fallback;
  }

  static CategoryMetadata resolve(TransactionCategory category) {
    return _registry[category] ?? _fallback;
  }
}