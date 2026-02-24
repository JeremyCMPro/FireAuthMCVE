import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class ChangeEmailPage extends StatefulWidget {
  const ChangeEmailPage({super.key});

  @override
  State<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  final _newEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  String _getErrorMessage(FirebaseAuthException e) {
    developer.log(
      'Firebase Auth Error: ${e.code} - ${e.message}',
      name: 'ChangeEmail',
    );

    switch (e.code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'email-already-in-use':
        return 'This email address is already in use by another account.';
      case 'wrong-password':
        return 'The current password is incorrect.';
      case 'user-mismatch':
        return 'The credentials do not match the current user.';
      case 'user-not-found':
        return 'User not found.';
      case 'invalid-credential':
        return 'The provided credentials are invalid.';
      case 'requires-recent-login':
        return 'This operation requires a recent login. Please logout and login again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Error: ${e.message ?? e.code}';
    }
  }

  Future<void> _changeEmail() async {
    if (!_formKey.currentState!.validate()) {
      developer.log('Form validation failed', name: 'ChangeEmail');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      developer.log('No user logged in', name: 'ChangeEmail', level: 1000);
      _showSnackBar('No user logged in', isError: true);
      return;
    }

    if (_newEmailController.text.trim() == user.email) {
      _showSnackBar(
        'The new email is identical to the current email',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    developer.log(
      'Starting email change from ${user.email} to ${_newEmailController.text}',
      name: 'ChangeEmail',
    );

    try {
      developer.log('Attempting reauthentication...', name: 'ChangeEmail');
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: user.email!,
        password: _passwordController.text,
      );
      developer.log('Reauthentication successful', name: 'ChangeEmail');

      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser == null) {
        throw Exception('User not found after reauthentication');
      }

      developer.log('Attempting to update email...', name: 'ChangeEmail');
      await refreshedUser.verifyBeforeUpdateEmail(
        _newEmailController.text.trim(),
      );
      developer.log(
        'Email mis à jour avec succès: ${_newEmailController.text}',
        name: 'ChangeEmail',
      );

      if (!mounted) return;
      _showSnackBar('Email changed successfully!');

      _newEmailController.clear();
      _passwordController.clear();

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    } on FirebaseAuthException catch (e) {
      developer.log(
        'Firebase Auth error: ${e.code}',
        name: 'ChangeEmail',
        error: e,
        level: 1000,
      );
      _showSnackBar(_getErrorMessage(e), isError: true);
    } catch (e, stackTrace) {
      developer.log(
        'Unexpected error',
        name: 'ChangeEmail',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      _showSnackBar('Unexpected error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Change Email')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Current email: ${user?.email ?? "Not logged in"}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _newEmailController,
                decoration: const InputDecoration(
                  labelText: 'New Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!value.contains('@')) {
                    return 'Invalid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _changeEmail,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Change Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _newEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
