import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/firebase/firebase_runtime_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap(
    config: FirebaseRuntimeConfig.fromEnvironment(),
  ).initialize();

  runApp(const ProviderScope(child: FamilyTreeApp()));
}
