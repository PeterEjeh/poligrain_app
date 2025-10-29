import 'package:flutter/material.dart';
import 'package:poligrain_app/services/auth_service.dart';
import 'package:poligrain_app/screens/auth/login_screen.dart';

class AuthGuard extends StatefulWidget {
  final Widget child;
  final Widget? loadingWidget;
  final Widget? unauthorizedWidget;

  const AuthGuard({
    super.key,
    required this.child,
    this.loadingWidget,
    this.unauthorizedWidget,
  });

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isAuthenticated = await AuthService().isAuthenticated();
      setState(() {
        _isAuthenticated = isAuthenticated;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingWidget ??
          const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAuthenticated) {
      return widget.unauthorizedWidget ?? const LoginScreen();
    }

    return widget.child;
  }
}
