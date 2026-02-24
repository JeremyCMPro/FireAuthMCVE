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
    developer.log('Firebase Auth Error: ${e.code} - ${e.message}', name: 'ChangeEmail');

    switch (e.code) {
      case 'invalid-email':
        return 'L\'adresse email n\'est pas valide.';
      case 'email-already-in-use':
        return 'Cette adresse email est déjà utilisée par un autre compte.';
      case 'wrong-password':
        return 'Le mot de passe actuel est incorrect.';
      case 'user-mismatch':
        return 'Les identifiants ne correspondent pas à l\'utilisateur actuel.';
      case 'user-not-found':
        return 'Utilisateur non trouvé.';
      case 'invalid-credential':
        return 'Les identifiants fournis sont invalides.';
      case 'requires-recent-login':
        return 'Cette opération nécessite une reconnexion récente. Veuillez vous déconnecter et vous reconnecter.';
      case 'too-many-requests':
        return 'Trop de tentatives. Veuillez réessayer plus tard.';
      case 'network-request-failed':
        return 'Erreur réseau. Vérifiez votre connexion internet.';
      default:
        return 'Erreur: ${e.message ?? e.code}';
    }
  }

  Future<void> _changeEmail() async {
    if (!_formKey.currentState!.validate()) {
      developer.log('Validation du formulaire échouée', name: 'ChangeEmail');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      developer.log('Aucun utilisateur connecté', name: 'ChangeEmail', level: 1000);
      _showSnackBar('Aucun utilisateur connecté', isError: true);
      return;
    }

    if (_newEmailController.text.trim() == user.email) {
      _showSnackBar('Le nouvel email est identique à l\'email actuel', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    developer.log('Début du changement d\'email de ${user.email} vers ${_newEmailController.text}', name: 'ChangeEmail');

    try {
      // Réauthentification en utilisant signInWithEmailAndPassword au lieu de reauthenticateWithCredential
      // pour éviter le bug de cast de type dans Firebase Auth
      developer.log('Tentative de réauthentification...', name: 'ChangeEmail');
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: user.email!,
        password: _passwordController.text,
      );
      developer.log('Réauthentification réussie', name: 'ChangeEmail');

      // Récupérer l'utilisateur actualisé
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser == null) {
        throw Exception('Utilisateur non trouvé après réauthentification');
      }

      // Mise à jour de l'email directement
      developer.log('Tentative de mise à jour de l\'email...', name: 'ChangeEmail');
      await refreshedUser.verifyBeforeUpdateEmail(_newEmailController.text.trim());
      developer.log('Email mis à jour avec succès: ${_newEmailController.text}', name: 'ChangeEmail');

      if (!mounted) return;
      _showSnackBar('Email changé avec succès !');

      // Nettoyer les champs
      _newEmailController.clear();
      _passwordController.clear();

      // Retour à la page d'accueil après un délai
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    } on FirebaseAuthException catch (e) {
      developer.log('Erreur Firebase Auth: ${e.code}', name: 'ChangeEmail', error: e, level: 1000);
      _showSnackBar(_getErrorMessage(e), isError: true);
    } catch (e, stackTrace) {
      developer.log('Erreur inattendue', name: 'ChangeEmail', error: e, stackTrace: stackTrace, level: 1000);
      _showSnackBar('Erreur inattendue: ${e.toString()}', isError: true);
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
      appBar: AppBar(title: const Text('Changer l\'email')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Email actuel: ${user?.email ?? "Non connecté"}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _newEmailController,
                decoration: const InputDecoration(
                  labelText: 'Nouvel email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un email';
                  }
                  if (!value.contains('@')) {
                    return 'Email invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe actuel',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre mot de passe';
                  }
                  if (value.length < 6) {
                    return 'Le mot de passe doit contenir au moins 6 caractères';
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
                    : const Text('Changer l\'email'),
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