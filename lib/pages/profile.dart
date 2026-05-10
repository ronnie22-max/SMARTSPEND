import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartspend/main.dart';
import 'package:smartspend/services/user_data_service.dart';

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
  bool _hasSecurityPin = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final securityPin = await UserDataService().loadSecurityPin();
    if (!mounted) return;

    setState(() {
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
      _biometricLockEnabled = prefs.getBool(_biometricLockKey) ?? false;
      _monthlyReminderEnabled = prefs.getBool(_monthlyReminderKey) ?? true;
      _wifiBackupEnabled = prefs.getBool(_wifiBackupKey) ?? true;
      _preferredCurrency = prefs.getString(_currencyKey) ?? 'UGX';
      _hasSecurityPin = securityPin != null;
      _settingsLoaded = true;
    });
  }

  Future<void> _showPinDialog() async {
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();
    String? errorText;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                _hasSecurityPin ? 'Change 4-Digit PIN' : 'Set 4-Digit PIN',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      labelText: 'Enter PIN',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      labelText: 'Confirm PIN',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(errorText!, style: const TextStyle(color: Colors.red)),
                  ],
                  if (_hasSecurityPin) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, false);
                          _showForgotPinDialog();
                        },
                        child: const Text(
                          'Forgot PIN?',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final pin = pinController.text.trim();
                    final confirmPin = confirmPinController.text.trim();
                    if (pin.length != 4 || int.tryParse(pin) == null) {
                      setDialogState(() {
                        errorText = 'PIN must be exactly 4 digits';
                      });
                      return;
                    }
                    if (pin != confirmPin) {
                      setDialogState(() {
                        errorText = 'PINs do not match';
                      });
                      return;
                    }
                    await UserDataService().saveSecurityPin(pin);
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    pinController.dispose();
    confirmPinController.dispose();

    if (saved == true && mounted) {
      setState(() {
        _hasSecurityPin = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('4-digit PIN saved successfully')),
      );
    }
  }

  Future<void> _showForgotPinDialog() async {
    final passwordController = TextEditingController();
    String? errorText;

    final reset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reset PIN'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter your account password to reset your PIN.'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(errorText!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final password = passwordController.text.trim();
                    if (password.isEmpty) {
                      setDialogState(() {
                        errorText = 'Please enter your password';
                      });
                      return;
                    }

                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user?.email == null) {
                        setDialogState(() {
                          errorText = 'User not found';
                        });
                        return;
                      }

                      // Reauthenticate with email and password
                      final credential = EmailAuthProvider.credential(
                        email: user!.email!,
                        password: password,
                      );
                      await user.reauthenticateWithCredential(credential);

                      // If successful, reset the PIN
                      await UserDataService().saveSecurityPin('0000');
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext, true);
                    } on FirebaseAuthException catch (e) {
                      setDialogState(() {
                        errorText = e.message ?? 'Authentication failed';
                      });
                    } catch (e) {
                      setDialogState(() {
                        errorText = 'Error: $e';
                      });
                    }
                  },
                  child: const Text('Reset PIN'),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();

    if (reset == true && mounted) {
      setState(() {
        _hasSecurityPin = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'PIN reset to default (0000). Please change it immediately.',
          ),
        ),
      );
    }
  }

  Future<void> _showPasswordChangeDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    String? errorText;

    final changed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(errorText!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final currentPassword = currentPasswordController.text
                        .trim();
                    final newPassword = newPasswordController.text.trim();
                    final confirmPassword = confirmPasswordController.text
                        .trim();

                    if (currentPassword.isEmpty ||
                        newPassword.isEmpty ||
                        confirmPassword.isEmpty) {
                      setDialogState(() {
                        errorText = 'All fields are required';
                      });
                      return;
                    }

                    if (newPassword.length < 6) {
                      setDialogState(() {
                        errorText =
                            'New password must be at least 6 characters';
                      });
                      return;
                    }

                    if (newPassword != confirmPassword) {
                      setDialogState(() {
                        errorText = 'New passwords do not match';
                      });
                      return;
                    }

                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user?.email == null) {
                        setDialogState(() {
                          errorText = 'User not found';
                        });
                        return;
                      }

                      // Reauthenticate with current password
                      final credential = EmailAuthProvider.credential(
                        email: user!.email!,
                        password: currentPassword,
                      );
                      await user.reauthenticateWithCredential(credential);

                      // Update password
                      await user.updatePassword(newPassword);

                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext, true);
                    } on FirebaseAuthException catch (e) {
                      setDialogState(() {
                        errorText = e.message ?? 'Authentication failed';
                      });
                    } catch (e) {
                      setDialogState(() {
                        errorText = 'Error: $e';
                      });
                    }
                  },
                  child: const Text('Change Password'),
                ),
              ],
            );
          },
        );
      },
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
    }
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

  Future<void> _showUsernameDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final controller = TextEditingController(
      text: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : (user.email?.split('@').first ?? ''),
    );
    String? errorText;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Change Username'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(errorText!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final username = controller.text.trim();
                    if (username.length < 2) {
                      setDialogState(() {
                        errorText = 'Username must be at least 2 characters';
                      });
                      return;
                    }
                    await user.updateDisplayName(username);
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (saved == true && mounted) {
      await FirebaseAuth.instance.currentUser?.reload();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated successfully')),
      );
    }
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile'),
        backgroundColor: Colors.green,
        actions: [IconButton(icon: const Icon(Icons.share), onPressed: () {})],
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
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black54),
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
            if (!_settingsLoaded) const LinearProgressIndicator(minHeight: 2),
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
              subtitle: const Text(
                'Get alerts for bills, spending and updates',
              ),
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
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Change Username'),
              subtitle: Text(displayName),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showUsernameDialog,
            ),
            ListTile(
              leading: const Icon(Icons.pin_outlined),
              title: Text(
                _hasSecurityPin ? 'Change 4-Digit PIN' : 'Set 4-Digit PIN',
              ),
              subtitle: const Text(
                'Required to view balance and access deposit or withdrawal',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showPinDialog,
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Change Password'),
              subtitle: const Text('Update your account password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showPasswordChangeDialog,
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
