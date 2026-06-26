import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    ref.read(authCodeServiceProvider).readLastCode().then((value) {
      if (mounted && value != null) {
        _controller.text = value;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context);
    final ok = await ref.read(authSessionProvider.notifier).login(_controller.text);
    if (!ok && mounted) {
      setState(() => _error = l10n.invalidCode);
    }
  }
}
