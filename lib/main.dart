import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flosy/core/network_check.dart';
import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/features/auth/screens/cubit/auth_cubit_cubit.dart';
import 'package:flosy/features/home/presentation/cubit/home_cubit.dart';
import 'package:flosy/features/home/presentation/services/db.dart';
import 'package:flosy/features/settings/cubit/settings_cubit.dart';
import 'package:flosy/firebase_options.dart';
import 'package:flosy/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dbService.init();
  final AppTheme appTheme = AppTheme();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: Flosy(appTheme: appTheme),
    ),
  );
}

class Flosy extends StatelessWidget {
  final AppTheme appTheme;
  const Flosy({super.key, required this.appTheme});

  @override
  Widget build(BuildContext context) {
    // Perform network check here where context is available
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => AuthCubit()),
            BlocProvider(create: (context) => SettingsCubit()..loadSettings()),
            BlocProvider(create: (context) => HomeCubit()),
          ],
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, state) {
              ThemeMode themeMode = ThemeMode.system;
              if (state is SettingsLoaded) {
                themeMode = state.themeMode;
              }
              return MaterialApp(
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                debugShowCheckedModeBanner: false,
                theme: appTheme.lightTheme,
                darkTheme: appTheme.darkTheme,
                themeMode: themeMode,
                home: SplashScreen(),
              );
            },
          ),
        );
      },
    );
  }
}
