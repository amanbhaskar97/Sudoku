import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/rendering.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'providers/game_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();
  
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  
  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => GameProvider(prefs: prefs)),
        ChangeNotifierProvider(create: (context) => ThemeProvider(prefs: prefs)),
        ChangeNotifierProvider(create: (context) => UserAuthProvider()),
      ],
      child: Consumer2<ThemeProvider, UserAuthProvider>(
        builder: (context, themeProvider, authProvider, child) {
          return MaterialApp(
            title: 'Sudoku',
            theme: themeProvider.theme,
            home: authProvider.isAuthenticated
                ? const HomeScreen()
                : const LoginScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
} 