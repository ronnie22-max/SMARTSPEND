import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _confirmAndLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

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
            const CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage('assets/avatar.png'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ronnie Ssempijja',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('ronnie@example.com'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & feedback'),
            ),
            ListTile(
              leading: const Icon(Icons.outbond),
              title: const Text('logout'),
              onTap: () => _confirmAndLogout(context),
            ),
          ],
        ),
      ),
    );
  }
}
