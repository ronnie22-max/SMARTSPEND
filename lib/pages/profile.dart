import 'package:flutter/material.dart';


class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color.fromARGB(255, 0, 0, 0)),
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/home');
          },
        ),
        title: Text('Profile'), 
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Color.fromARGB(255, 0, 0, 0)),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(radius: 40, backgroundImage: AssetImage('assets/avatar.png')),
            const SizedBox(height: 12),
            const Text('Ronnie Ssempijja', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('ronnie@example.com'),
            const SizedBox(height: 16),
            ListTile(leading: const Icon(Icons.settings), title: const Text('Settings')),
            ListTile(leading: const Icon(Icons.help), title: const Text('Help & feedback')),
            ListTile(leading: const Icon(Icons.outbond), title: const Text('logout')),
          ],
        ),
      ),
    );
  }
}