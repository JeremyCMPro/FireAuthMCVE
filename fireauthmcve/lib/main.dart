import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import 'change_email.dart';
import 'firebase_options.dart';
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  developer.log('Initializing Firebase...', name: 'App');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  developer.log('Firebase initialized successfully', name: 'App');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth MCVE',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            developer.log('Waiting for authentication state...', name: 'App');
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            developer.log(
              'Error in authentication stream',
              name: 'App',
              error: snapshot.error,
              level: 1000,
            );
            return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            );
          }

          if (snapshot.hasData) {
            developer.log(
              'User logged in: ${snapshot.data?.email}',
              name: 'App',
            );
            return const HomePage();
          }

          developer.log('No user logged in', name: 'App');
          return const LoginPage();
        },
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      developer.log('Logging out...', name: 'HomePage');
      await FirebaseAuth.instance.signOut();
      developer.log('Logout successful', name: 'HomePage');
      _showSnackBar(context, 'Logout successful');
    } catch (e) {
      developer.log(
        'Error during logout',
        name: 'HomePage',
        error: e,
        level: 1000,
      );
      _showSnackBar(context, 'Error during logout: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Home'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Logged in as:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.email ?? 'Email not available',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'UID: ${user?.uid ?? 'Not available'}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                developer.log(
                  'Navigating to change email page',
                  name: 'HomePage',
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangeEmailPage()),
                );
              },
              icon: const Icon(Icons.email),
              label: const Text('Change Email'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
