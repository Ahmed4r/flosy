// lib/features/home/domain/transaction_category.dart
//
// Domain-level category identity. This is what the database/Firestore
// layer is allowed to know about: a stable string id. No Flutter icon
// types are referenced here.

enum TransactionCategory {
  food,
  rent,
  transport,
  shopping,
  fun,
  health,
  salary,
  more,
  unknown; // fallback for legacy/unrecognized category strings

  /// The stable id persisted in SQLite and Firestore.
  /// This is the ONLY representation of category that should ever
  /// touch the database layer.
  String get id => name;

  /// Looks up a canonical category by its stored id. Also tolerates a
  /// handful of known aliases (legacy/AI-generated strings, Arabic labels)
  /// so data written before this refactor — or written by the AI-parsing
  /// path — still resolves to the right icon/color/label.
  static TransactionCategory fromId(String? raw) {
    if (raw == null) return TransactionCategory.unknown;
    final key = raw.trim().toLowerCase();
    if (key.isEmpty) return TransactionCategory.unknown;

    for (final c in TransactionCategory.values) {
      if (c.id == key) return c;
    }
    return _aliases[key] ?? TransactionCategory.unknown;
  }

  /// Known synonyms (mainly Arabic labels seen from the AI-parsing path)
  /// mapped to the canonical id. Add entries here rather than special
  /// casing them anywhere else in the app.
  static const Map<String, TransactionCategory> _aliases = {
    'اكل': TransactionCategory.food,
    'أكل': TransactionCategory.food,
    'طعام': TransactionCategory.food,
    'ايجار': TransactionCategory.rent,
    'إيجار': TransactionCategory.rent,
    'مسكن': TransactionCategory.rent,
    'مواصلات': TransactionCategory.transport,
    'نقل': TransactionCategory.transport,
    'سوبر ماركت': TransactionCategory.shopping,
    'تسوق': TransactionCategory.shopping,
    'ترفيه': TransactionCategory.fun,
    'فن': TransactionCategory.fun,
    'صحة': TransactionCategory.health,
    'راتب': TransactionCategory.salary,
    'دخل': TransactionCategory.salary,
    'عام': TransactionCategory.more,
    'اخرى': TransactionCategory.more,
    'أخرى': TransactionCategory.more,
  };

  /// Use when writing a NEW category value into storage from an untrusted
  /// or free-form source (AI JSON, imported data). Known ids/aliases are
  /// normalized to the canonical id (e.g. "اكل" -> "food") so grouping and
  /// icon lookup stay consistent with manually-added transactions.
  /// A genuinely unrecognized string is kept as-is (trimmed) rather than
  /// collapsed to "unknown", so the original label isn't lost — the
  /// presentation layer already falls back to a generic icon for it.
  static String normalizeForStorage(String? raw) {
    if (raw == null) return TransactionCategory.more.id;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return TransactionCategory.more.id;
    final resolved = fromId(trimmed);
    return resolved == TransactionCategory.unknown
        ? trimmed
        : resolved.id;
  }
}