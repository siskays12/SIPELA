// lib/main.dart
import 'package:flutter/material.dart';
import 'core/api_service.dart';
import 'screens/shared/login_screen.dart';
import 'screens/shared/main_screen.dart';
import 'widgets/app_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final token = await ApiService.getToken();
  runApp(SipelaApp(isLoggedIn: token != null));
}

class SipelaApp extends StatelessWidget {
  final bool isLoggedIn;
  const SipelaApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIPELA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kBrandPrimary,
          surface: kSurface,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: kBackground,
        dividerColor: kBorder,
        appBarTheme: const AppBarTheme(
          backgroundColor: kSurface,
          foregroundColor: kTextMain,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: kTextMain,
          ),
        ),
      ),
      home: isLoggedIn ? const MainScreen() : const LoginScreen(),
    );
  }
}
