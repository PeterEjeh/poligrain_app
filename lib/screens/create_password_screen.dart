import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'profile_setup_screen.dart';

class CreatePasswordScreen extends StatefulWidget {
  final String email;
  const CreatePasswordScreen({super.key, required this.email});

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _setState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newPassword.text != _confirmPassword.text) {
      return _setState(() => _error = 'Passwords do not match');
    }

    _setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Sign out any existing session to avoid conflicts
      print('Signing out any existing session');
      await Amplify.Auth.signOut().catchError((e) => print('No session to sign out: $e'));

      print('Attempting sign-in for ${widget.email}');
      const tempPassword = 'TemporaryP@ssw0rd123!';
      final signIn = await Amplify.Auth.signIn(
        username: widget.email,
        password: tempPassword,
      );
      print('SignIn result: isSignedIn=${signIn.isSignedIn}, nextStep=${signIn.nextStep?.signInStep}');

      final nextStep = signIn.nextStep?.signInStep;

      if (signIn.isSignedIn || nextStep == AuthSignInStep.done) {
        print('Updating password');
        await Amplify.Auth.updatePassword(
          oldPassword: tempPassword,
          newPassword: _newPassword.text.trim(),
        );
        _navigateToProfileSetup();
      } else if (nextStep == AuthSignInStep.confirmSignInWithNewPassword) {
        print('Confirming sign-in with new password');
        final confirm = await Amplify.Auth.confirmSignIn(
          confirmationValue: _newPassword.text.trim(),
        );
        print('ConfirmSignIn result: isSignedIn=${confirm.isSignedIn}, nextStep=${confirm.nextStep?.signInStep}');
        if (confirm.isSignedIn) {
          _navigateToProfileSetup();
        } else {
          _setState(() => _error = 'Sign-in incomplete. Step: ${confirm.nextStep?.signInStep ?? "Unknown"}');
        }
      } else {
        _setState(() => _error = 'Unexpected sign-in step: ${nextStep?.name ?? "Unknown"}');
      }
    } catch (e) {
      print('Sign-in error: $e');
      _setState(() => _error = 'Sign-in failed: $e');
    } finally {
      _setState(() => _loading = false);
    }
  }

  void _navigateToProfileSetup() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileSetupScreen(email: widget.email),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create new password',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create password to continue',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 30),
                TextFormField(
                  controller: _newPassword,
                  obscureText: true, // Password hidden, no toggle
                  decoration: InputDecoration(
                    hintText: 'New Password',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.black45,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                  ),
                  validator: _passwordValidator,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPassword,
                  obscureText: true, // Password hidden, no toggle
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.black45,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                  ),
                  validator: (v) =>
                  v != _newPassword.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700, // Match green theme
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _loading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) return 'Enter a password';
    if (value.length < 8) return 'Minimum 8 characters';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Add a lowercase letter';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Add an uppercase letter';
    if (!RegExp(r'\d').hasMatch(value)) return 'Add a number';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Add a special character';
    }
    return null;
  }
}