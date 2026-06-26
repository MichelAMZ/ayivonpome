import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'family_tree_provider.dart';

final localeProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() => null;

  Future<void> setLocale(String languageCode) async {
    state = Locale(languageCode);
    await ref.read(familyTreeProvider.notifier).setLanguage(languageCode);
  }
}
