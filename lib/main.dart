import 'package:flutter/material.dart';
import 'package:smartspend/firebase_options.dart';
import 'package:smartspend/pages/cash.dart';
import 'package:smartspend/pages/login.dart';
import 'package:smartspend/pages/transaction.dart';
import 'package:smartspend/pages/profile.dart';
import 'package:smartspend/pages/home.dart';
import 'package:smartspend/pages/splash.dart';
import 'package:smartspend/pages/signup.dart';
import 'package:smartspend/pages/bills.dart';
//import 'package:smartspend/pages/budget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global notifier – any widget can read or change the app theme.
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore saved theme preference
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('dark_mode') ?? false;
  themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  final firebaseReady = await _initializeFirebaseSafely();
  runApp(MyApp(firebaseReady: firebaseReady));
}

Future<bool> _initializeFirebaseSafely() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } on UnsupportedError catch (e) {
    debugPrint('Firebase is not configured for this platform: $e');
    return false;
  } catch (e, s) {
    debugPrint('Firebase init failed: $e');
    debugPrintStack(stackTrace: s);
    return false;
  }
}

class MyApp extends StatelessWidget {
  final bool firebaseReady;

  const MyApp({super.key, required this.firebaseReady});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => const SplashPage(),
            '/login': (context) => LoginPage(firebaseReady: firebaseReady),
            '/signup': (context) => const SignUpPage(),
            '/transactions': (context) => TransactionsPage(),
            '/profile': (context) => const ProfilePage(),
            '/bills': (context) => BillsPage(),
            '/cash': (context) => const CashPage(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/home') {
              final username = settings.arguments as String? ?? '';
              return MaterialPageRoute(
                builder: (context) => HomePage(username: username),
              );
            }
            return null;
          },
        );
      },
    );
  }
}
