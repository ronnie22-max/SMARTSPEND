import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartspend/main.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const String _notificationsKey = 'notifications_enabled';
  static const String _biometricLockKey = 'biometric_lock_enabled';
  static const String _monthlyReminderKey = 'monthly_reminder_enabled';
  static const String _wifiBackupKey = 'wifi_backup_enabled';
  static const String _currencyKey = 'preferred_currency';

  bool _notificationsEnabled = true;
  bool _biometricLockEnabled = false;
  bool _monthlyReminderEnabled = true;
  bool _wifiBackupEnabled = true;
  String _preferredCurrency = 'UGX';
  bool _settingsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
      _biometricLockEnabled = prefs.getBool(_biometricLockKey) ?? false;
      _monthlyReminderEnabled = prefs.getBool(_monthlyReminderKey) ?? true;
      _wifiBackupEnabled = prefs.getBool(_wifiBackupKey) ?? true;
      _preferredCurrency = prefs.getString(_currencyKey) ?? 'UGX';
      _settingsLoaded = true;
    });
  }

  Future<void> _saveBoolSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveStringSetting(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _toggleDarkMode(bool value) async {
    themeModeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
  }

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

  String _initialFromName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'U';
    final first = trimmed[0].toUpperCase();
    final letterOnly = RegExp(r'[A-Z0-9]').hasMatch(first);
    return letterOnly ? first : 'U';
  }

  Future<void> _pickCurrency() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        final currencies = ['UGX', 'USD', 'KES', 'EUR'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: currencies
                .map(
                  (currency) => ListTile(
                    leading: Icon(
                      _preferredCurrency == currency
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                    ),
                    title: Text(currency),
                    onTap: () => Navigator.pop(context, currency),
                  ),
                )
                .toList(),
          ),
        );
      },
    );

    if (selected == null || selected == _preferredCurrency) return;

    setState(() {
      _preferredCurrency = selected;
    });
    await _saveStringSetting(_currencyKey, selected);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : (user?.email?.split('@').first ?? 'SmartSpend User');
    final email = user?.email ?? 'Not signed in';
    final initial = _initialFromName(displayName);
    final isDarkMode = themeModeNotifier.value == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/home');
          },
        ),
        title: const Text('Profile'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.green.withValues(alpha: 0.20),
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SmartSpend Account',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black54,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 220,
                        child: Divider(
                          color: Colors.green.withValues(alpha: 0.25),
                          height: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.settings),
              title: Text(
                'App Settings',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (!_settingsLoaded)
              const LinearProgressIndicator(minHeight: 2),
            SwitchListTile(
              secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
              title: const Text('Dark Mode'),
              subtitle: const Text('Use a darker color theme for the app'),
              value: isDarkMode,
              onChanged: _toggleDarkMode,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_active_outlined),
              title: const Text('Transaction Notifications'),
              subtitle: const Text('Get alerts for bills, spending and updates'),
              value: _notificationsEnabled,
              onChanged: (value) async {
                setState(() => _notificationsEnabled = value);
                await _saveBoolSetting(_notificationsKey, value);
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.lock_outline),
              title: const Text('Biometric Lock'),
              subtitle: const Text('Require fingerprint/face to open app'),
              value: _biometricLockEnabled,
              onChanged: (value) async {
                setState(() => _biometricLockEnabled = value);
                await _saveBoolSetting(_biometricLockKey, value);
              },
            ),
            ListTile(
              leading: const Icon(Icons.currency_exchange),
              title: const Text('Preferred Currency'),
              subtitle: Text(_preferredCurrency),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickCurrency,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.calendar_month_outlined),
              title: const Text('Monthly Budget Reminder'),
              subtitle: const Text('Get a reminder to review your budget'),
              value: _monthlyReminderEnabled,
              onChanged: (value) async {
                setState(() => _monthlyReminderEnabled = value);
                await _saveBoolSetting(_monthlyReminderKey, value);
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.backup_outlined),
              title: const Text('Back Up on Wi-Fi Only'),
              subtitle: const Text('Sync app data when connected to Wi-Fi'),
              value: _wifiBackupEnabled,
              onChanged: (value) async {
                setState(() => _wifiBackupEnabled = value);
                await _saveBoolSetting(_wifiBackupKey, value);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Feedback'),
              subtitle: const Text('Support, FAQs and contact options'),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => _confirmAndLogout(context),
            ),
          ],
        ),
      ),
    );
  }
}
