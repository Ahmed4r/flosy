import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class SettingsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final ThemeMode themeMode;
  final bool isDarkMode;
  final bool faceIdEnabled;
  final String selectedCurrency;
  final File? profileImage;
  final bool isSyncing;
  final bool internetAvailable; // شيلنا late
  final bool isCloudDataDeleted;

  SettingsLoaded({
    required this.themeMode,
    required this.isDarkMode,
    required this.faceIdEnabled,
    required this.selectedCurrency,
    this.profileImage,
    required this.isSyncing,
    required this.internetAvailable,
    required this.isCloudDataDeleted,
  });

  // هذا هو الجزء الذي يخبر الـ Bloc بأن الحالة تغيرت فعلاً
  @override
  List<Object?> get props => [
    themeMode,
    isDarkMode,
    faceIdEnabled,
    selectedCurrency,
    profileImage,
    isSyncing, // السويتش يعتمد على هذا
    internetAvailable,
    isCloudDataDeleted,
  ];
}

class SettingsError extends SettingsState {
  final String message;
  SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}
