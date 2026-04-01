import 'package:flutter/material.dart';
import 'package:smartspend/pages/cash.dart';
import 'package:smartspend/pages/login.dart';
import 'package:smartspend/pages/transaction.dart';
import 'package:smartspend/pages/profile.dart';
import 'package:smartspend/pages/home.dart';
import 'package:smartspend/pages/splash.dart';
import 'package:smartspend/pages/signup.dart';
import 'package:smartspend/pages/bills.dart';
//import 'package:smartspend/pages/budget.dart';



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       debugShowCheckedModeBanner: false,  
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/transactions': (context) => TransactionsPage(),
        '/profile': (context) => const ProfilePage(),
        '/bills': (context) => billsPage(),
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
  }
}
