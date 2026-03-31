import 'package:flutter/material.dart';
import 'package:smartspend/pages/login.dart';
import 'package:smartspend/pages/transaction.dart';
import 'package:smartspend/pages/profile.dart';
import 'package:smartspend/pages/home.dart';
import 'package:smartspend/pages/splash.dart';
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
      initialRoute: '/home',
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => HomePage(username: ''),
        '/transactions': (context) => TransactionsPage(),
        '/profile': (context) => const ProfilePage(),
        '/splash': (context) => const SignUpPage(),
        '/bills': (context) => billsPage(),
        //'/budgets': (context) => BudgetPage(),

        
      },
    );    
  }
}
