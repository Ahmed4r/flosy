import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flosy/core/network_check.dart';
import 'package:flosy/features/home/presentation/services/db.dart';
import 'package:flosy/features/settings/cubit/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

import '../../home/presentation/cubit/home_cubit.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(SettingsInitial());

  final LocalAuthentication _localAuth = LocalAuthentication();
  ThemeMode _currentThemeMode = ThemeMode.system;
  bool _isDarkMode = false;
  bool _faceIdEnabled = false;
  String _selectedCurrency = 'USD';
  File? _image;
  File? get profileImage => _image;
  late SharedPreferences _prefs;
  bool _isSyncing = false;
  bool internetAvailable = false;
  final bool _isCloudDataDeleted = false;
  String userName = '';

  ThemeMode get currentThemeMode => _currentThemeMode;
  bool get isDarkMode => _isDarkMode;
  bool get faceIdEnabled => _faceIdEnabled;
  String get selectedCurrency => _selectedCurrency;
  bool get isSyncing => _isSyncing;
  bool get isInternetAvailable => internetAvailable;
  bool get isCloudDataDeleted => _isCloudDataDeleted;

  NetworkCheck networkCheck = NetworkCheck();

  // Try to get the user name from prefs -> FirebaseAuth -> Firestore, and save to prefs.
  Future<String> getUserName() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      final cached = _prefs.getString('user_name');
      if (cached != null && cached.isNotEmpty) {
        userName = cached;
        return userName;
      }

      final authUser = FirebaseAuth.instance.currentUser;
      final displayName = authUser?.displayName;
      if (displayName != null && displayName.isNotEmpty) {
        userName = displayName;
        await _prefs.setString('user_name', userName);
        return userName;
      }

      if (authUser != null) {
        final store = FirebaseFirestore.instance;
        final doc = await store.collection('users').doc(authUser.uid).get();
        if (doc.exists) {
          final nameFromFirestore =
              doc.data()?['userName'] as String? ?? 'User';
          userName = nameFromFirestore;
          await _prefs.setString('user_name', userName);
          return userName;
        }
      }

      userName = _prefs.getString('user_name') ?? '';
      await _prefs.setString('user_name', userName);
      return userName;
    } catch (e) {
      log("Error fetching user name: $e");
      userName = 'User';
      try {
        _prefs = await SharedPreferences.getInstance();
        await _prefs.setString('user_name', userName);
      } catch (_) {}
      return userName;
    } finally {
      if (state is SettingsLoaded) {
        final s = state as SettingsLoaded;
        emit(
          SettingsLoaded(
            themeMode: s.themeMode,
            isDarkMode: s.isDarkMode,
            faceIdEnabled: s.faceIdEnabled,
            selectedCurrency: s.selectedCurrency,
            profileImage: s.profileImage,
            isSyncing: s.isSyncing,
            internetAvailable: s.internetAvailable,
            isCloudDataDeleted: s.isCloudDataDeleted,
          ),
        );
      }
    }
  }

  // Save user name to SharedPreferences, Firebase Auth displayName, and Firestore
  Future<void> saveUserName(String name) async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _prefs.setString('user_name', name);
      userName = name;

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(name);
        final store = FirebaseFirestore.instance;
        await store.collection('users').doc(user.uid).set({
          'userName': name,
          'lastSync': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (state is SettingsLoaded) {
        final s = state as SettingsLoaded;
        emit(
          SettingsLoaded(
            themeMode: s.themeMode,
            isDarkMode: s.isDarkMode,
            faceIdEnabled: s.faceIdEnabled,
            selectedCurrency: s.selectedCurrency,
            profileImage: s.profileImage,
            isSyncing: s.isSyncing,
            internetAvailable: s.internetAvailable,
            isCloudDataDeleted: s.isCloudDataDeleted,
          ),
        );
      }
    } catch (e) {
      log("Failed to save user name: $e");
      emit(SettingsError('Failed to save user name: ${e.toString()}'));
    }
  }

  Future<void> toggleSync(bool isSyncing, BuildContext context) async {
    try {
      internetAvailable = await networkCheck.checkNetwork(context);

      if (internetAvailable) {
        _isSyncing = isSyncing;
        await _prefs.setBool('is_syncing', isSyncing);

        // منطق ذكي: لا ترفع البيانات إلا إذا كانت المزامنة ON وهناك بيانات فعلياً
        final homeCubit = context.read<HomeCubit>();
        if (isSyncing && homeCubit.transactions.isNotEmpty) {
          await syncTransactionsToCloud(context);
          log('✅ Data synced because sync was turned ON');
        }
        // إذا كانت OFF، نحن فقط نغير الإعداد ولا نلمس الفايربيز
        else if (!isSyncing) {
          log('Sync turned OFF - Cloud data remains as is');
        }

        _emitLoadedState(); // دالة مساعدة لتقليل تكرار الكود
      } else {
        // إذا لم يوجد إنترنت، ارفض تغيير حالة السويتش
        _emitLoadedState();
      }
    } catch (e) {
      log(e.toString());
      emit(SettingsError('Failed to toggle sync: ${e.toString()}'));
    }
  }

  void _emitLoadedState() {
    emit(
      SettingsLoaded(
        themeMode: _currentThemeMode,
        isDarkMode: _isDarkMode,
        faceIdEnabled: _faceIdEnabled,
        selectedCurrency: _selectedCurrency,
        profileImage: _image,
        isSyncing: _isSyncing, // القيمة اللي اتغيرت لـ false
        internetAvailable: internetAvailable,
        isCloudDataDeleted: true,
      ),
    );
  }

  Future<void> deleteCloudData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final store = FirebaseFirestore.instance;
    final batch = store.batch();

    // 1. حذف كل المعاملات من السحاب
    final snapshot = await store
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .get();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    // 2. تصفير العدادات تماماً
    final userDocRef = store.collection('users').doc(user.uid);
    batch.update(userDocRef, {
      // استخدم update بدلاً من set لضمان عدم المساس ببيانات أخرى
      'totalBalance': 0.0,
      'totalIncome': 0.0,
      'totalExpense': 0.0,
      'lastSync': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    log("✅ Cloud data wiped clean");
  }

  Future<void> clearCloudData() async {
    try {
      await deleteCloudData();

      // 1. تحديث المتغير المحلي
      _isSyncing = false;
      await _prefs.setBool('is_syncing', false);

      // 2. إرسال كائن جديد تماماً (New Reference)
      emit(
        SettingsLoaded(
          themeMode: _currentThemeMode,
          isDarkMode: _isDarkMode,
          faceIdEnabled: _faceIdEnabled,
          selectedCurrency: _selectedCurrency,
          profileImage: _image,
          isSyncing: false, // قيمة صريحة
          internetAvailable: internetAvailable,
          isCloudDataDeleted: true,
        ),
      );

      log('✅ تم إرسال حالة جديدة تماماً والقيمة فيها false');
    } catch (e) {
      _emitLoadedState();
    }
  }

  Future<void> clearLocalData(BuildContext context) async {
    try {
      await dbService.deleteAllTransactions();
      log('Local data cleared successfully');
      final user = FirebaseAuth.instance.currentUser;
      await user?.updateDisplayName('');
      _prefs.remove('total_balance');
      emit(
        SettingsLoaded(
          themeMode: _currentThemeMode,
          isDarkMode: _isDarkMode,
          faceIdEnabled: _faceIdEnabled,
          selectedCurrency: _selectedCurrency,
          profileImage: null,
          isSyncing: _isSyncing,
          internetAvailable: internetAvailable,
          isCloudDataDeleted: _isCloudDataDeleted,
        ),
      );
    } catch (e) {
      log(e.toString());
      emit(SettingsError('Failed to clear local data: ${e.toString()}'));
    }
  }

  Future<void> clearAllData(BuildContext context) async {
    try {
      emit(SettingsLoading());

      // // مسح السحاب
      // await deleteCloudData();

      // مسح المحلي
      await dbService.deleteAllTransactions();
      await _prefs.remove('total_balance');
      _image = null;
      await _prefs.remove('profile_image');

      // تصفير المزامنة محلياً وحفظها
      _isSyncing = false;
      await _prefs.setBool('is_syncing', false);

      // تصفير اسم المستخدم
      final user = FirebaseAuth.instance.currentUser;
      await user?.updateDisplayName('');

      log('✅ All data cleared & sync killed');

      // إرسال حالة واحدة نهائية
      _emitLoadedState();
    } catch (e) {
      log("❌ Error: $e");
      emit(SettingsError(e.toString()));
      _emitLoadedState();
    }
  }

  Future<void> syncTransactionsToCloud(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    // 1. جلب البيانات من قاعدة البيانات المحلية ومن Cubit أو Prefs
    final transactions = await dbService.getTransactions();
    final homeCubit = context.read<HomeCubit>(); // نفترض أن البيانات موجودة هنا
    final prefs = await SharedPreferences.getInstance();

    // جلب القيم (لو مش موجودة في الـ Cubit، هاتها من الـ Prefs مباشرة)
    final double totalBalance = homeCubit.totalBalance;
    final double totalIncome = homeCubit.totalIncome;
    final double totalExpense = homeCubit.totalExpenses;
    final String userName =
        user.displayName ?? "User"; // من Firebase Auth أو Prefs

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    // 2. تحديث بيانات المستخدم العامة (الملخص)
    final userDocRef = firestore.collection('users').doc(user.uid);
    batch.set(userDocRef, {
      'userName': userName ?? 'Guest',
      'totalBalance': totalBalance ?? 0.0,
      'totalIncome': totalIncome ?? 0.0,
      'totalExpense': totalExpense ?? 0.0,
      'lastSync': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 3. تحديث قائمة المعاملات
    for (final tx in transactions) {
      final docRef = userDocRef
          .collection('transactions')
          .doc(tx.id.toString());

      batch.set(docRef, tx.toMap(), SetOptions(merge: true));
    }

    // 4. تنفيذ العملية دفعة واحدة (Batch)
    try {
      await batch.commit();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_sync', DateTime.now().millisecondsSinceEpoch);
      log("✅ تم مزامنة البيانات والملخص بنجاح!");
    } catch (e) {
      log("❌ Cloud sync failed: $e");
    }
  }

  Future<void> loadSettings() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      // Load theme mode
      final themeModeIndex = _prefs.getInt('theme_mode') ?? 0;
      _currentThemeMode = ThemeMode.values[themeModeIndex];
      _isDarkMode = _prefs.getBool('is_dark_mode') ?? false;

      // Load other settings
      _faceIdEnabled = _prefs.getBool('face_id_enabled') ?? false;
      _selectedCurrency = _prefs.getString('selected_currency') ?? 'USD';
      _image = _prefs.getString('profile_image') != null
          ? File(_prefs.getString('profile_image')!)
          : null;
      _isSyncing = _prefs.getBool('is_syncing') ?? false;

      emit(
        SettingsLoaded(
          themeMode: _currentThemeMode,
          isDarkMode: _isDarkMode,
          faceIdEnabled: _faceIdEnabled,
          selectedCurrency: _selectedCurrency,
          profileImage: _image,
          isSyncing: _isSyncing,
          internetAvailable: internetAvailable,
          isCloudDataDeleted: _isCloudDataDeleted,
        ),
      );
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> updateProfileImage(File? image) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;

      // Update the instance variable
      _image = image;

      // Force a new emission by creating a completely new state
      emit(SettingsLoading()); // Emit loading first

      // Save to SharedPreferences with the correct key
      if (image != null) {
        await _prefs.setString(
          'profile_image',
          image.path,
        ); // Changed from 'profile_image_path'
      } else {
        await _prefs.remove('profile_image');
      }

      // Emit the new state
      emit(
        SettingsLoaded(
          selectedCurrency: currentState.selectedCurrency,
          isDarkMode: currentState.isDarkMode,
          faceIdEnabled: currentState.faceIdEnabled,
          profileImage: image,
          themeMode: _currentThemeMode,
          isSyncing: _isSyncing,
          internetAvailable: internetAvailable,
          isCloudDataDeleted: _isCloudDataDeleted,
        ),
      );
    }
  }

  Future<void> toggleTheme(bool isDark) async {
    try {
      _isDarkMode = isDark;
      _currentThemeMode = isDark ? ThemeMode.dark : ThemeMode.light;

      await _prefs.setBool('is_dark_mode', _isDarkMode);
      await _prefs.setInt('theme_mode', _currentThemeMode.index);

      emit(
        SettingsLoaded(
          themeMode: _currentThemeMode,
          isDarkMode: _isDarkMode,
          faceIdEnabled: _faceIdEnabled,
          selectedCurrency: _selectedCurrency,
          profileImage: _image,
          isSyncing: _isSyncing,
          internetAvailable: internetAvailable,
          isCloudDataDeleted: _isCloudDataDeleted,
        ),
      );
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<bool> checkBiometricAvailability() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final bool canAuthenticate = await checkBiometricAvailability();

      if (!canAuthenticate) {
        return false;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to enable biometric login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  Future<void> toggleFaceId(bool enabled) async {
    try {
      if (enabled) {
        // Check if biometric is available
        final canAuthenticate = await checkBiometricAvailability();
        if (!canAuthenticate) {
          emit(
            SettingsError(
              'Biometric authentication is not available on this device',
            ),
          );
          return;
        }

        // Authenticate before enabling
        final authenticated = await authenticateWithBiometrics();
        if (!authenticated) {
          emit(SettingsError('Authentication failed'));
          // Re-emit current state without changing the value
          emit(
            SettingsLoaded(
              themeMode: _currentThemeMode,
              isDarkMode: _isDarkMode,
              faceIdEnabled: _faceIdEnabled,
              selectedCurrency: _selectedCurrency,
              profileImage: _image,
              isSyncing: _isSyncing,
              internetAvailable: internetAvailable,
              isCloudDataDeleted: _isCloudDataDeleted,
            ),
          );
          return;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      _faceIdEnabled = enabled;
      await prefs.setBool('face_id_enabled', _faceIdEnabled);

      emit(
        SettingsLoaded(
          themeMode: _currentThemeMode,
          isDarkMode: _isDarkMode,
          faceIdEnabled: _faceIdEnabled,
          selectedCurrency: _selectedCurrency,
          profileImage: _image,
          isSyncing: _isSyncing,
          internetAvailable: internetAvailable,
          isCloudDataDeleted: _isCloudDataDeleted,
        ),
      );
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> changeCurrency(String currency) async {
    try {
      _selectedCurrency = currency;
      await _prefs.setString('selected_currency', _selectedCurrency);
      emit(
        SettingsLoaded(
          themeMode: _currentThemeMode,
          isDarkMode: _isDarkMode,
          faceIdEnabled: _faceIdEnabled,
          selectedCurrency: _selectedCurrency,
          profileImage: _image,
          isSyncing: _isSyncing,
          internetAvailable: internetAvailable,
          isCloudDataDeleted: _isCloudDataDeleted,
        ),
      );
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }
}
