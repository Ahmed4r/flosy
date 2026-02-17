part of 'settings_cubit.dart';

@immutable
abstract class SettingsState {}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final ThemeMode themeMode;
  final bool isDarkMode;
  final bool faceIdEnabled;
  final String selectedCurrency;
  final File? profileImage;
  final bool isSyncing;
  SettingsLoaded({
    required this.themeMode,
    required this.isDarkMode,
    required this.faceIdEnabled,
    required this.selectedCurrency,
    this.profileImage,
    required this.isSyncing,
  });
}

class SettingsError extends SettingsState {
  final String message;
  SettingsError(this.message);
}
