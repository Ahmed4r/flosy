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
  final bool internetAvailable;
  final bool isCloudDataDeleted;
  final String userName; // This should NEVER be null

  SettingsLoaded({
    required this.themeMode,
    required this.isDarkMode,
    required this.faceIdEnabled,
    required this.selectedCurrency,
    this.profileImage,
    required this.isSyncing,
    required this.internetAvailable,
    required this.isCloudDataDeleted,
    this.userName = '', // Default to empty string, NEVER null
  });

  // CRITICAL: Include userName in props so changes are detected
  @override
  List<Object?> get props => [
        themeMode,
        isDarkMode,
        faceIdEnabled,
        selectedCurrency,
        profileImage,
        isSyncing,
        internetAvailable,
        isCloudDataDeleted,
        userName, // ← MUST be included!
      ];

  // CopyWith method for easy state updates
  SettingsLoaded copyWith({
    ThemeMode? themeMode,
    bool? isDarkMode,
    bool? faceIdEnabled,
    String? selectedCurrency,
    File? profileImage,
    bool? isSyncing,
    bool? internetAvailable,
    bool? isCloudDataDeleted,
    String? userName,
  }) {
    return SettingsLoaded(
      themeMode: themeMode ?? this.themeMode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      faceIdEnabled: faceIdEnabled ?? this.faceIdEnabled,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      profileImage: profileImage ?? this.profileImage,
      isSyncing: isSyncing ?? this.isSyncing,
      internetAvailable: internetAvailable ?? this.internetAvailable,
      isCloudDataDeleted: isCloudDataDeleted ?? this.isCloudDataDeleted,
      userName: userName ?? this.userName,
    );
  }
}

class SettingsError extends SettingsState {
  final String message;
  SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}