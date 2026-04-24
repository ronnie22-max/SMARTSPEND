import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with TickerProviderStateMixin {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  String errorMessage = "";
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  late AnimationController _headerController;
  late AnimationController _formController;
  late Animation<Offset> _headerSlide;
  late Animation<double> _headerFade;
  late Animation<Offset> _formSlide;
  late Animation<double> _formFade;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _formController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerController, curve: Curves.easeOut));

    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeIn),
    );

    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _formController, curve: Curves.easeOut));

    _formFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeIn),
    );

    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _formController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _formController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void handleSignUp() async {
    String username = usernameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() {
        errorMessage = "All fields are required";
      });
      return;
    }

    if (!email.contains("@") || !email.contains(".")) {
      setState(() {
        errorMessage = "Invalid email address";
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        errorMessage = "Password must be at least 6 characters";
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        errorMessage = "Passwords do not match";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      errorMessage = "";
    });

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await credential.user?.updateDisplayName(username);
      setState(() => _isLoading = false);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home', arguments: username);
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = "An account already exists with this email";
          break;
        case 'invalid-email':
          message = "Invalid email address";
          break;
        case 'weak-password':
          message = "Password is too weak. Use at least 6 characters";
          break;
        case 'operation-not-allowed':
          message = "Email/password sign-up is not enabled";
          break;
        default:
          message = "Sign-up failed. Please try again";
      }
      setState(() {
        errorMessage = message;
        _isLoading = false;
      });
    }
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      prefixIcon: Icon(icon, color: Colors.green.shade600),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.green.shade600, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade800,
              Colors.green.shade600,
              Colors.green.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.02),

              // Animated header
              SlideTransition(
                position: _headerSlide,
                child: FadeTransition(
                  opacity: _headerFade,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Register to start using SmartSpend',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.03),

              // Animated form card
              Expanded(
                child: SlideTransition(
                  position: _formSlide,
                  child: FadeTransition(
                    opacity: _formFade,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 36, 28, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Username
                            TextField(
                              controller: usernameController,
                              style: const TextStyle(fontSize: 16),
                              decoration: _buildInputDecoration(
                                label: 'Username',
                                icon: Icons.person_outline,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Email
                            TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(fontSize: 16),
                              decoration: _buildInputDecoration(
                                label: 'Email Address',
                                icon: Icons.email_outlined,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Password
                            TextField(
                              controller: passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(fontSize: 16),
                              decoration: _buildInputDecoration(
                                label: 'Password',
                                icon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.grey.shade500,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password
                            TextField(
                              controller: confirmPasswordController,
                              obscureText: _obscureConfirm,
                              style: const TextStyle(fontSize: 16),
                              decoration: _buildInputDecoration(
                                label: 'Confirm Password',
                                icon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.grey.shade500,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Error message
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              child: errorMessage.isNotEmpty
                                  ? Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.red.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.error_outline,
                                              color: Colors.red.shade400, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              errorMessage,
                                              style: TextStyle(
                                                  color: Colors.red.shade700, fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),

                            // Sign Up button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : handleSignUp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.green.shade300,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // OR divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey.shade300)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.grey.shade300)),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Google Sign-in
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: Image.network(
                                  "https://upload.wikimedia.org/wikipedia/commons/0/09/IOS_Google_icon.png",
                                  width: 22,
                                  height: 22,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.g_mobiledata, size: 26),
                                ),
                                label: const Text(
                                  'Continue with Google',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey.shade800,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Apple Sign-in
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.apple, size: 24),
                                label: const Text(
                                  'Continue with Apple',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            // Already have an account
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account?",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 15,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    "Login",
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
