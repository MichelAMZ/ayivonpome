import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _controller = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  String? _error;
  String? _adminError;
  String? _adminMessage;
  var _adminSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.family_restroom,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.loginTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: l10n.familyCode,
                    errorText: _error,
                    prefixIcon: const Icon(Icons.key),
                  ),
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _login,
                  icon: const Icon(Icons.login),
                  label: Text(l10n.enter),
                ),
                const SizedBox(height: 20),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('Connexion administrateur Firebase'),
                  children: [
                    const SizedBox(height: 8),
                    TextField(
                      controller: _adminEmailController,
                      enabled: !_adminSubmitting,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email administrateur',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _adminPasswordController,
                      enabled: !_adminSubmitting,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        errorText: _adminError,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      onSubmitted: (_) => _loginFirebaseAdmin(),
                    ),
                    if (_adminMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _adminMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _adminSubmitting
                                ? null
                                : _sendFirebasePasswordReset,
                            icon: const Icon(Icons.mark_email_read_outlined),
                            label: const Text('Réinitialiser'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _adminSubmitting
                                ? null
                                : _loginFirebaseAdmin,
                            icon: const Icon(Icons.verified_user_outlined),
                            label: const Text('Se connecter'),
                          ),
                        ),
                      ],
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

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context);
    final ok = await ref
        .read(authSessionProvider.notifier)
        .login(_controller.text);
    if (!ok && mounted) {
      setState(() => _error = l10n.invalidCode);
    }
  }

  Future<void> _loginFirebaseAdmin() async {
    final email = _adminEmailController.text.trim();
    final password = _adminPasswordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _adminError = 'Email et mot de passe requis.';
        _adminMessage = null;
      });
      return;
    }
    setState(() {
      _adminSubmitting = true;
      _adminError = null;
      _adminMessage = null;
    });
    try {
      await ref
          .read(authSessionProvider.notifier)
          .loginFirebaseAdmin(email: email, password: password);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _adminSubmitting = false;
        _adminError = _friendlyFirebaseError(error);
      });
      return;
    }
    if (!mounted) return;
    setState(() => _adminSubmitting = false);
  }

  Future<void> _sendFirebasePasswordReset() async {
    final email = _adminEmailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _adminError = 'Email administrateur requis.';
        _adminMessage = null;
      });
      return;
    }
    setState(() {
      _adminSubmitting = true;
      _adminError = null;
      _adminMessage = null;
    });
    try {
      await ref
          .read(authSessionProvider.notifier)
          .sendFirebasePasswordReset(email);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _adminSubmitting = false;
        _adminError = _friendlyFirebaseError(error);
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _adminSubmitting = false;
      _adminMessage = 'Email de réinitialisation envoyé.';
    });
  }

  String _friendlyFirebaseError(Object error) {
    final message = error.toString();
    if (message.contains('user-not-found') ||
        message.contains('wrong-password') ||
        message.contains('invalid-credential')) {
      return 'Identifiants administrateur invalides.';
    }
    if (message.contains('permission-denied')) {
      return 'Rôle Firestore inaccessible pour ce compte.';
    }
    return message.replaceFirst('Exception: ', '');
  }
}
