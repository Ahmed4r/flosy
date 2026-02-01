import 'package:flosy/core/theme/app_theme.dart';
import 'package:flosy/splash_screen.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final AppTheme? appTheme = AppTheme();
  runApp(Flosy(appTheme: appTheme!));
}

class Flosy extends StatelessWidget {
  final AppTheme appTheme;
  const Flosy({super.key, required this.appTheme});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: const SplashScreen(),
      theme: appTheme.lightTheme,
      darkTheme: appTheme.lightTheme,
      themeMode: ThemeMode.light,
    );
  }
}
