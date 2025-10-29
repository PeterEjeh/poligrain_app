import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'dart:ui'; // For ImageFilter
import 'package:flutter/services.dart'; // For PlatformException
import 'signup_screen.dart';
import 'package:local_auth/local_auth.dart'; // Import local_auth
import 'forgot_password_screen.dart';
import 'package:poligrain_app/main_screen_wrapper.dart';
import 'package:poligrain_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poligrain_app/screens/profile/profile_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? initialEmail;
  const LoginScreen({super.key, this.initialEmail});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _errorMessage;
  bool _passwordVisible = false;
  bool _isLoading = false;
  bool _isCheckingSession = true;
  final LocalAuthentication _localAuth = LocalAuthentication();
  int _loginAttempts = 0;
  final int _maxLoginAttempts = 3;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();
    _passwordVisible = false;
    _isCheckingSession = false;
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Start animations
    _startAnimations();
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeController.forward();
      _slideController.forward();
      _scaleController.forward();
    });
  }

  Future<bool> _authenticateWithBiometrics() async {
    try {
      // Check if device supports biometrics
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Biometric authentication is not available on this device.';
          });
        }
        return false;
      }

      // Get available biometrics
      final List<BiometricType> availableBiometrics =
          await _localAuth.getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'No biometric authentication methods are set up on this device.';
          });
        }
        return false;
      }

      // Attempt to authenticate
      final bool isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!isAuthenticated && mounted) {
        setState(() {
          _errorMessage =
              'Authentication was cancelled or failed. Please try again.';
        });
      }

      return isAuthenticated;
    } on PlatformException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'NotAvailable':
          errorMessage =
              'Biometric authentication is not available on this device.';
          break;
        case 'NotEnrolled':
          errorMessage =
              'No biometric authentication methods are set up on this device.';
          break;
        case 'LockedOut':
          errorMessage =
              'Biometric authentication is temporarily locked. Please try again later.';
          break;
        case 'PermanentlyLockedOut':
          errorMessage =
              'Biometric authentication is permanently locked. Please use password login.';
          break;
        default:
          errorMessage =
              'An error occurred during authentication. Please try again.';
      }

      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
        });
      }
      safePrint('Biometric authentication error: ${e.message}');
      return false;
    } catch (e) {
      safePrint('Error during biometric authentication: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
      }
      return false;
    }
  }

  Future<void> _checkCurrentUserSession() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (session.isSignedIn) {
        // User is signed in, attempt biometric authentication
        final isAuthenticated = await _authenticateWithBiometrics();
        if (isAuthenticated) {
          // Check if profile is complete
          final authService = AuthService();
          final isProfileComplete = await authService.isProfileComplete();

          if (mounted) {
            if (isProfileComplete) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MainScreenWrapper()),
              );
            } else {
              // Get current user email for profile setup
              final currentUser = await Amplify.Auth.getCurrentUser();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => ProfileSetupScreen(email: currentUser.username),
                ),
              );
            }
          }
        } else {
          // Biometric authentication failed or was cancelled
          if (mounted) {
            setState(() {
              _isCheckingSession = false;
              // Don't set error message here as it's already set in _authenticateWithBiometrics
            });
          }
        }
      } else {
        // User is not signed in, check if biometrics are available
        final bool canAuthenticateWithBiometrics =
            await _localAuth.canCheckBiometrics;
        final bool canAuthenticate =
            canAuthenticateWithBiometrics ||
            await _localAuth.isDeviceSupported();

        if (canAuthenticate) {
          // If biometrics are available, attempt authentication
          final isAuthenticated = await _authenticateWithBiometrics();
          if (isAuthenticated) {
            // If biometric authentication succeeds, attempt to sign in with stored credentials
            // Note: You'll need to implement secure storage for credentials
            // For now, we'll just show the login screen
            if (mounted) {
              setState(() => _isCheckingSession = false);
            }
          } else {
            if (mounted) {
              setState(() => _isCheckingSession = false);
            }
          }
        } else {
          // No biometrics available, show login screen
          if (mounted) {
            setState(() => _isCheckingSession = false);
          }
        }
      }
    } catch (e) {
      safePrint('Error during authentication: $e');
      if (mounted) {
        setState(() {
          _isCheckingSession = false;
          _errorMessage =
              'An error occurred during authentication. Please try again.';
        });
      }
    }
  }

  Future<void> _login() async {
    // Check for internet connection first
    if (!await AuthService().hasInternetConnection()) {
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('No Internet Connection'),
                content: const Text(
                  'Please check your internet connection and try again.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First check if there's an existing session and sign out
      final session = await Amplify.Auth.fetchAuthSession();
      if (session.isSignedIn) {
        await Amplify.Auth.signOut();
      }

      // Proceed with sign in
      final result = await Amplify.Auth.signIn(
        username: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (result.isSignedIn) {
        // Save email to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('lastEmail', _emailController.text.trim());
        _loginAttempts = 0; // Reset login attempts on successful login

        // Check if profile is complete
        final authService = AuthService();
        final isProfileComplete = await authService.isProfileComplete();

        if (mounted) {
          if (isProfileComplete) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainScreenWrapper()),
            );
          } else {
            // Get the actual user email from attributes for profile setup
            final userAttributes = await authService.fetchUserAttributes();
            final userEmail =
                userAttributes['email'] ?? _emailController.text.trim();

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileSetupScreen(email: userEmail),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Sign in process not completed. Additional steps may be required.';
          });
        }
      }
    } on AuthException catch (e) {
      String friendlyMessage;
      if (e is UserNotFoundException) {
        friendlyMessage = 'User not found. Please check your email or sign up.';
      } else if (e.runtimeType.toString() == 'NotAuthorizedException') {
        // Wrong password case
        if (mounted) {
          setState(() {
            _loginAttempts++;
            if (_loginAttempts >= _maxLoginAttempts) {
              // Lock further login attempts and require email verification/reset
              _isLoading = false; // ensure button state updates
              _errorMessage =
                  'Too many failed login attempts. We\'ve sent a verification code to your email. Please verify to reset your password or try again.';
            } else {
              _errorMessage =
                  'Incorrect email or password. You have ${_maxLoginAttempts - _loginAttempts} tries remaining.';
            }
          });
        }

        // After reaching the max attempts, kick off the password reset flow and navigate
        if (_loginAttempts >= _maxLoginAttempts) {
          try {
            await Amplify.Auth.resetPassword(
              username: _emailController.text.trim(),
            );
          } catch (resetErr) {
            safePrint('Failed to initiate resetPassword: $resetErr');
          }

          if (mounted) {
            // Navigate to the Forgot Password screen so the user can enter the code and set a new password
            final resetCompleted = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
            );
            if (mounted && resetCompleted == true) {
              // User successfully verified and set a new password
              setState(() {
                _loginAttempts = 0;
                _errorMessage =
                    'Password reset completed. Please login with your new password.';
              });
            }
          }
        }
        return; // Exit to prevent further setState calls outside this block
      } else if (e is UserNotConfirmedException) {
        friendlyMessage =
            'User not confirmed. Please check your email for a confirmation code.';
        // Example: you might want to pass the email to a confirmation screen
        // String username = _emailController.text.trim();
        // Navigator.push(context, MaterialPageRoute(builder: (context) => ConfirmSignUpScreen(username: username)));
      } else if (e is PasswordResetRequiredException) {
        friendlyMessage = 'Password reset is required for this user.';
        // Navigate to a password reset screen
      } else {
        friendlyMessage = e.message;
        safePrint('Login AuthException: ${e.toString()}');
      }
      if (mounted) {
        setState(() => _errorMessage = friendlyMessage);
      }
    } catch (e) {
      safePrint('Generic login error: ${e.toString()}');
      if (mounted) {
        setState(
          () =>
              _errorMessage = 'An unexpected error occurred. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  "Checking session...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Image.asset('assets/images/trans_bg.png', height: 140),
                const SizedBox(height: 16),
                Column(
                  children: const [
                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Sign in to continue',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 22,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        _buildSimpleTextField(
                          controller: _emailController,
                          hintText: 'Enter your email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator:
                              (value) =>
                                  value == null ||
                                          value.isEmpty ||
                                          !value.contains('@')
                                      ? 'Enter a valid email'
                                      : null,
                        ),
                        const SizedBox(height: 12),
                        _buildSimpleTextField(
                          controller: _passwordController,
                          hintText: 'Enter your password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: !_passwordVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey[600],
                            ),
                            onPressed:
                                () => setState(
                                  () => _passwordVisible = !_passwordVisible,
                                ),
                          ),
                          validator:
                              (value) =>
                                  value == null || value.length < 6
                                      ? 'Password must be at least 6 characters'
                                      : null,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : () async {
                                      final resetCompleted = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) =>
                                                  const ForgotPasswordScreen(),
                                        ),
                                      );
                                      if (mounted && resetCompleted == true) {
                                        setState(() {
                                          _loginAttempts = 0;
                                          _errorMessage =
                                              'Password reset completed. Please login with your new password.';
                                        });
                                      }
                                    },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(color: Color(0xFF2E7D32)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed:
                                _isLoading ||
                                        _loginAttempts >= _maxLoginAttempts
                                    ? null
                                    : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text(
                                      'Login',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[300])),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                              ),
                              child: Text(
                                'Or Login with',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey[300])),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed:
                                _isLoading ||
                                        _loginAttempts >= _maxLoginAttempts
                                    ? null
                                    : () {
                                      /* TODO: Google sign-in */
                                    },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/google.png',
                                  height: 22,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    TextButton(
                      onPressed:
                          _isLoading || _loginAttempts >= _maxLoginAttempts
                              ? null
                              : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignupScreen(),
                                  ),
                                );
                              },
                      child: const Text(
                        'Register Now',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextFormField(
            controller: controller,
            enabled: !_isLoading,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
              prefixIcon: Icon(
                prefixIcon,
                color: Colors.white.withOpacity(0.7),
                size: 22,
              ),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
            validator: validator,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedButton({
    required VoidCallback? onPressed,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              onPressed != null
                  ? const Color(0xFF2E7D32)
                  : Colors.grey.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: onPressed != null ? 6 : 0,
        ),
        child: child,
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback? onPressed,
    required Widget icon,
    required String label,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.9),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: icon,
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2E7D32), width: 1.2),
      ),
      child: TextFormField(
        controller: controller,
        enabled: !_isLoading,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.grey[800]),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(prefixIcon, color: Colors.grey[600]),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}
