// lib/features/settings/domain/currency_metadata.dart
//
// Same pattern as TransactionCategory/CategoryRegistry: a typed enum for
// identity + a centralized metadata registry for presentation (icon,
// symbol, display name). Replaces `List<Map<String, dynamic>> currencies`
// and the `currency['icon'] as FaIconData` unsafe cast.

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum AppCurrency {
  usd,
  eur,
  gbp,
  egp,
  sar,
  aed,
  jpy,
  cny;

  /// The stable code used everywhere else in the app (SettingsCubit,
  /// stored preference, etc.) — unchanged from the original string codes.
  String get code => name.toUpperCase();

  static AppCurrency fromCode(String? code) {
    if (code == null) return AppCurrency.eur;
    return AppCurrency.values.firstWhere(
      (c) => c.code == code.toUpperCase(),
      orElse: () => AppCurrency.eur,
    );
  }
}

class CurrencyMetadata {
  final AppCurrency currency;
  final String displayName;
  final String symbol;
  final FaIconData icon;

  const CurrencyMetadata({
    required this.currency,
    required this.displayName,
    required this.symbol,
    required this.icon,
  });

  String get code => currency.code;
}

class CurrencyRegistry {
  CurrencyRegistry._();

  static const Map<AppCurrency, CurrencyMetadata> _registry = {
    AppCurrency.usd: CurrencyMetadata(
      currency: AppCurrency.usd,
      displayName: 'US Dollar',
      symbol: '\$',
      icon: FontAwesomeIcons.dollarSign,
    ),
    AppCurrency.eur: CurrencyMetadata(
      currency: AppCurrency.eur,
      displayName: 'Euro',
      symbol: '€',
      icon: FontAwesomeIcons.euroSign,
    ),
    AppCurrency.gbp: CurrencyMetadata(
      currency: AppCurrency.gbp,
      displayName: 'British Pound',
      symbol: '£',
      icon: FontAwesomeIcons.sterlingSign,
    ),
    AppCurrency.egp: CurrencyMetadata(
      currency: AppCurrency.egp,
      displayName: 'Egyptian Pound',
      symbol: 'E£',
      icon: FontAwesomeIcons.moneyBill,
    ),
    AppCurrency.sar: CurrencyMetadata(
      currency: AppCurrency.sar,
      displayName: 'Saudi Riyal',
      symbol: 'SR',
      icon: FontAwesomeIcons.moneyBill1,
    ),
    AppCurrency.aed: CurrencyMetadata(
      currency: AppCurrency.aed,
      displayName: 'UAE Dirham',
      symbol: 'AED',
      icon: FontAwesomeIcons.coins,
    ),
    AppCurrency.jpy: CurrencyMetadata(
      currency: AppCurrency.jpy,
      displayName: 'Japanese Yen',
      symbol: '¥',
      icon: FontAwesomeIcons.yenSign,
    ),
    AppCurrency.cny: CurrencyMetadata(
      currency: AppCurrency.cny,
      displayName: 'Chinese Yuan',
      symbol: '¥',
      icon: FontAwesomeIcons.yenSign,
    ),
  };

  /// Stable display order, drives the list.
  static List<CurrencyMetadata> get all => _registry.values.toList();

  static CurrencyMetadata resolve(AppCurrency currency) =>
      _registry[currency] ?? _registry[AppCurrency.eur]!;

  static CurrencyMetadata resolveByCode(String? code) =>
      resolve(AppCurrency.fromCode(code));
}
