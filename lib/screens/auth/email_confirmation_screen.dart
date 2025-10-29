import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'create_password_screen.dart';

class EmailConfirmationScreen extends StatefulWidget {
  final String email;
  const EmailConfirmationScreen({super.key, required this.email});

  @override
  _EmailConfirmationScreenState createState() =>
      _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState extends State<EmailConfirmationScreen> {
  final _emailController = TextEditingController();
  final _confirmationCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  bool _isLoading = false; // To show a loading indicator on the button
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email;
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Amplify.Auth.signUp(
        username: _emailController.text.trim(),
        password: 'TemporaryP@ssw0rd123!',
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: _emailController.text.trim(),
          },
        ),
      );
      setState(() {
        _emailSent = true;
        _errorMessage = // Provide feedback that code was sent
            'A confirmation code has been sent to ${_emailController.text.trim()}.';
      });
    } on UsernameExistsException {
      // User already exists, likely pending confirmation. Resend code.
      try {
        await Amplify.Auth.resendSignUpCode(
          username: _emailController.text.trim(),
        );
        setState(() {
          _emailSent = true;
          _errorMessage =
              'Account already exists. A new confirmation code has been sent to ${_emailController.text.trim()}.';
        });
      } on AuthException catch (e) {
        setState(() {
          _errorMessage = 'Error resending code: ${e.message}';
        });
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmEmailAndProceed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();

    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: email,
        confirmationCode: _confirmationCodeController.text.trim(),
      );
      print('ConfirmSignUp result: ${result.isSignUpComplete}');

      if (result.isSignUpComplete) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CreatePasswordScreen(email: email),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Sign-up is not yet complete. Please try again.';
        });
      }
    } on CodeMismatchException {
      setState(() {
        _errorMessage = 'Incorrect confirmation code.';
      });
    } on ExpiredCodeException {
      setState(() {
        _errorMessage =
            'The confirmation code has expired. Please resend and try again.';
      });
    } on AuthException catch (e) {
      // Some backends may throw when the user is already confirmed.
      // If the message indicates the user is already CONFIRMED, proceed.
      final msg = (e.message).toLowerCase();
      final alreadyConfirmed =
          msg.contains('already confirmed') ||
          msg.contains('current status is confirmed') ||
          msg.contains('user is already confirmed');
      if (alreadyConfirmed) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CreatePasswordScreen(email: email),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Confirmation failed: ${e.message}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _confirmationCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          // Added for small screens
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.stretch, // Make children stretch
              children: <Widget>[
                const Icon(
                  Icons.mail_outline_rounded, // Using a rounded outline icon
                  size: 80,
                  color: Colors.black, // Icon color in the image is black
                ),
                const SizedBox(height: 24),
                Text(
                  _emailSent
                      ? 'Enter confirmation code'
                      : 'Confirm your email address',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22, // Adjusted font size
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                if (_emailSent)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      'Enter the code sent to ${_emailController.text.trim()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ),
                if (_errorMessage != null && _errorMessage!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            _errorMessage!.contains("code has been sent") ||
                                    _errorMessage!.contains(
                                      "confirmation code was sent",
                                    )
                                ? Colors
                                    .green
                                    .shade700 // Green for success/info messages
                                : Colors.red.shade700, // Red for error messages
                        fontSize: 14,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                if (!_emailSent)
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Enter your email',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Colors.grey[600],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.green.shade700, // Green border
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color:
                              Colors
                                  .green
                                  .shade600, // Green border when enabled
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color:
                              Colors
                                  .green
                                  .shade800, // Darker green when focused
                          width: 2.0,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                if (_emailSent)
                  TextFormField(
                    controller: _confirmationCodeController,
                    decoration: InputDecoration(
                      hintText: 'Enter confirmation code',
                      prefixIcon: Icon(
                        Icons.pin_outlined,
                        color: Colors.grey[600],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.green.shade700,
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.green.shade600,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.green.shade800,
                          width: 2.0,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the confirmation code';
                      }
                      if (value.length < 6) {
                        // Typical Cognito code length
                        return 'Code must be at least 6 digits';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : (_emailSent
                              ? _confirmEmailAndProceed
                              : _handleContinue),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700, // Green button
                    foregroundColor: Colors.white, // White text
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(double.infinity, 50), // Full width
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                          : Text(_emailSent ? 'Confirm & Proceed' : 'Continue'),
                ),
                if (_emailSent)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: TextButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () async {
                                setState(() => _isLoading = true);
                                try {
                                  await Amplify.Auth.resendSignUpCode(
                                    username: _emailController.text.trim(),
                                  );
                                  setState(() {
                                    _errorMessage =
                                        "A new confirmation code has been sent.";
                                  });
                                } on AuthException catch (e) {
                                  setState(() {
                                    _errorMessage =
                                        "Error resending code: ${e.message}";
                                  });
                                } finally {
                                  setState(() => _isLoading = false);
                                }
                              },
                      child: Text(
                        'Resend Code',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
