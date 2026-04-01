import 'package:flutter/material.dart';

class CashPage extends StatelessWidget {
  const CashPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Cash'),
      ),
      body: Center(
        child: Text(
          'Cash Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
