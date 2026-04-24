import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  final bool firebaseReady;

  const LoginPage({super.key, this.firebaseReady = true});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String errorMessage = "";
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

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
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void validateLogin() async {
    if (!widget.firebaseReady || Firebase.apps.isEmpty) {
      setState(() {
        errorMessage = 'Firebase is not configured for this platform yet.';
      });
      return;
    }

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => errorMessage = "Please fill in all fields");
      return;
    }

    setState(() {
      _isLoading = true;
      errorMessage = "";
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      final username = user?.displayName ?? user?.email ?? '';
      setState(() => _isLoading = false);
      if (mounted) Navigator.pushNamed(context, '/home', arguments: username);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = "No account found with this email";
          break;
        case 'wrong-password':
        case 'invalid-credential':
          message = "Wrong email or password";
          break;
        case 'invalid-email':
          message = "Invalid email address";
          break;
        case 'user-disabled':
          message = "This account has been disabled";
          break;
        case 'too-many-requests':
          message = "Too many attempts. Please try again later";
          break;
        default:
          message = "Login failed. Please try again";
      }
      setState(() {
        errorMessage = message;
        _isLoading = false;
      });
    }
  }

  Future<void> signInWithGoogle() async {
    if (!widget.firebaseReady || Firebase.apps.isEmpty) {
      setState(() {
        errorMessage = 'Firebase is not configured for this platform yet.';
      });
      return;
    }

    setState(() {
      _isGoogleLoading = true;
      errorMessage = '';
    });

    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.setCustomParameters({'prompt': 'select_account'});
        userCredential = await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          setState(() {
            _isGoogleLoading = false;
          });
          return;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
      }

      final user = userCredential.user;
      final username = user?.displayName ?? user?.email ?? '';
      setState(() {
        _isGoogleLoading = false;
      });
      if (mounted) {
        Navigator.pushNamed(context, '/home', arguments: username);
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          message = 'Account already exists with a different sign-in method';
          break;
        case 'popup-closed-by-user':
          message = 'Google sign-in was canceled';
          break;
        default:
          message = 'Google sign-in failed. Please try again';
      }
      setState(() {
        errorMessage = message;
        _isGoogleLoading = false;
      });
    } catch (_) {
      setState(() {
        errorMessage = 'Google sign-in failed. Please try again';
        _isGoogleLoading = false;
      });
    }
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
              SizedBox(height: screenHeight * 0.03),

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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to continue managing your finances',
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

              SizedBox(height: screenHeight * 0.04),

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
                        padding: const EdgeInsets.fromLTRB(28, 40, 28, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Email field
                            TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(fontSize: 16),
                              decoration: InputDecoration(
                                labelText: 'Email or Phone',
                                labelStyle: TextStyle(color: Colors.grey.shade600),
                                prefixIcon: Icon(Icons.email_outlined, color: Colors.green.shade600),
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
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Password field
                            TextField(
                              controller: passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(fontSize: 16),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(color: Colors.grey.shade600),
                                prefixIcon: Icon(Icons.lock_outline, color: Colors.green.shade600),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: Colors.grey.shade500,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
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
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Forgot password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            // Error message with animation
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              child: errorMessage.isNotEmpty
                                  ? Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.red.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              errorMessage,
                                              style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),

                            // Login button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed:
                                    (_isLoading || _isGoogleLoading)
                                        ? null
                                        : validateLogin,
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
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 28),

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

                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton(
                                onPressed: (_isLoading || _isGoogleLoading)
                                    ? null
                                    : signInWithGoogle,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isGoogleLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SvgPicture.asset(
                                            'images/google_logo.svg',
                                            width: 20,
                                            height: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'Continue with Google',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            Center(
                              child: Text(
                                'New to SmartSpend?',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Sign Up button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/signup');
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.green.shade600, width: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'Create an Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Bottom text
                            Center(
                              child: Text(
                                'Join SmartSpend and take control of your spending',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                ),
                              ),
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
