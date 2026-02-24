import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import 'change_email.dart';
import 'firebase_options.dart';
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  developer.log('Initialisation de Firebase...', name: 'App');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  developer.log('Firebase initialisé avec succès', name: 'App');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth MCVE',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            developer.log('En attente de l\'état d\'authentification...', name: 'App');
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          if (snapshot.hasError) {
            developer.log('Erreur dans le stream d\'authentification', name: 'App', error: snapshot.error, level: 1000);
            return Scaffold(
              body: Center(
                child: Text('Erreur: ${snapshot.error}'),
              ),
            );
          }
          
          if (snapshot.hasData) {
            developer.log('Utilisateur connecté: ${snapshot.data?.email}', name: 'App');
            return const HomePage();
          }
          
          developer.log('Aucun utilisateur connecté', name: 'App');
          return const LoginPage();
        },
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
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
      developer.log('Déconnexion en cours...', name: 'HomePage');
      await FirebaseAuth.instance.signOut();
      developer.log('Déconnexion réussie', name: 'HomePage');
      _showSnackBar(context, 'Déconnexion réussie');
    } catch (e) {
      developer.log('Erreur lors de la déconnexion', name: 'HomePage', error: e, level: 1000);
      _showSnackBar(context, 'Erreur lors de la déconnexion: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle_outline, size: 100, color: Colors.green),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Connecté en tant que:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.email ?? 'Email non disponible',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'UID: ${user?.uid ?? 'Non disponible'}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                developer.log('Navigation vers la page de changement d\'email', name: 'HomePage');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangeEmailPage()),
                );
              },
              icon: const Icon(Icons.email),
              label: const Text('Changer l\'email'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
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
