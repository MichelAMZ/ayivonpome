import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'core/logging/app_logger.dart';
import 'l10n/app_localizations.dart';
import 'config/app_environment.dart';
import 'providers/app_settings_provider.dart';
import 'providers/family_tree_provider.dart';
import 'providers/locale_provider.dart';
import 'widgets/app_shell.dart';

class FamilyTreeApp extends ConsumerWidget {
  const FamilyTreeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final data = ref.watch(familyTreeProvider);
    final appSettings = ref.watch(appSettingsProvider);
    final applicationTitle = appSettings.applicationTitle.trim().isEmpty
        ? 'FamilyTreeApp'
        : appSettings.applicationTitle.trim();
    debugPrint('MaterialApp locale: $locale');

    return MaterialApp(
      title: applicationTitle,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveAppLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: _premiumTheme(),
      builder: (context, child) => AppEnvironment.isStagingBuild
          ? Banner(
              message: 'PRÉPRODUCTION',
              location: BannerLocation.topEnd,
              color: const Color(0xFFC62828),
              child: child ?? const SizedBox.shrink(),
            )
          : child ?? const SizedBox.shrink(),
      home: data.when(
        loading: () => const _LoadingScreen(),
        error: (error, stackTrace) {
          final incident = error is AppInitializationFailure
              ? error.incident
              : AppLogger.capture(
                  category: 'bootstrap',
                  error: error,
                  stackTrace: stackTrace,
                );
          return _InitializationErrorScreen(incident: incident);
        },
        data: (_) {
          AppLogger.completeStep(BootstrapStep.appReady);
          return const AppShell();
        },
      ),
    );
  }
}

ThemeData _premiumTheme() {
  const primary = Color(0xFF405526);
  const onPrimary = Color(0xFFFFFFFF);
  const primaryContainer = Color(0xFFE8EEDB);
  const onPrimaryContainer = Color(0xFF1B2910);
  const secondary = Color(0xFF6A634F);
  const onSecondary = Color(0xFFFFFFFF);
  const secondaryContainer = Color(0xFFF0E9D8);
  const onSecondaryContainer = Color(0xFF292417);
  const tertiary = Color(0xFF9A762E);
  const onTertiary = Color(0xFFFFFFFF);
  const tertiaryContainer = Color(0xFFFFEBC0);
  const onTertiaryContainer = Color(0xFF342300);
  const surface = Color(0xFFFFFDF8);
  const surfaceContainer = Color(0xFFF6F3EB);
  const surfaceContainerHigh = Color(0xFFEDE9DF);
  const onSurface = Color(0xFF24261F);
  const onSurfaceVariant = Color(0xFF5E6156);
  const outline = Color(0xFF7A7E70);
  const outlineVariant = Color(0xFFD9DCCE);

  const colorScheme = ColorScheme.light(
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    tertiary: tertiary,
    onTertiary: onTertiary,
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: onTertiaryContainer,
    surface: surface,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceContainerHigh,
    onSurface: onSurface,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
    shadow: Color(0x1F1F2817),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFFFAF8F2),
    splashFactory: InkSparkle.splashFactory,
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.35,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        side: BorderSide(color: outlineVariant),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: outlineVariant,
      thickness: 1,
      space: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: onPrimary,
        backgroundColor: primary,
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        side: const BorderSide(color: outline),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: surfaceContainer,
      selectedColor: primaryContainer,
      side: const BorderSide(color: outlineVariant),
      shape: const StadiumBorder(),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: surface,
      indicatorColor: primaryContainer,
      selectedIconTheme: IconThemeData(color: primary),
      selectedLabelTextStyle: TextStyle(
        color: primary,
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: primaryContainer,
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: onSurface,
      contentTextStyle: TextStyle(color: surface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(
        color: onSurface,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      textStyle: TextStyle(color: surface),
    ),
  );
}

Locale resolveAppLocale(
  Locale? requestedLocale,
  Iterable<Locale> supportedLocales,
) {
  AppLogger.startStep(BootstrapStep.localeResolution);
  const fallback = Locale('fr');
  if (requestedLocale == null) {
    AppLogger.completeStep(BootstrapStep.localeResolution);
    return fallback;
  }

  for (final supportedLocale in supportedLocales) {
    if (supportedLocale.languageCode.toLowerCase() ==
        requestedLocale.languageCode.toLowerCase()) {
      AppLogger.completeStep(BootstrapStep.localeResolution);
      return supportedLocale;
    }
  }
  AppLogger.completeStep(BootstrapStep.localeResolution);
  return fallback;
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _InitializationErrorScreen extends ConsumerStatefulWidget {
  const _InitializationErrorScreen({required this.incident});

  final AppIncident incident;

  @override
  ConsumerState<_InitializationErrorScreen> createState() =>
      _InitializationErrorScreenState();
}

class _InitializationErrorScreenState
    extends ConsumerState<_InitializationErrorScreen> {
  var _retrying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Impossible de charger l’application.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Le chargement a échoué. Réessayez ou transmettez le code '
                  'd’assistance au support.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                SelectableText(
                  'Code d’assistance : ${widget.incident.id}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                SelectableText(
                  'Étape : ${widget.incident.step.name}\n'
                  'Erreur : ${widget.incident.errorType}\n'
                  '${widget.incident.safeMessage}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _retrying ? null : _retry,
                  icon: _retrying
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(_retrying ? 'Chargement…' : 'Réessayer'),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _copyIncident(context, widget.incident),
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copier les informations techniques'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _retry() async {
    setState(() => _retrying = true);
    await ref.read(familyTreeProvider.notifier).initializeAppFresh();
    if (mounted) setState(() => _retrying = false);
  }
}

class AppInlineError extends StatelessWidget {
  const AppInlineError({super.key, required this.incident});

  final AppIncident incident;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFFFAF8F4),
        child: DefaultTextStyle(
          style: const TextStyle(
            color: Color(0xFF252A24),
            fontSize: 16,
            decoration: TextDecoration.none,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Cette partie de la page n’a pas pu être affichée.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Code d’assistance : ${incident.id}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    button: true,
                    label: 'Copier les informations techniques',
                    child: GestureDetector(
                      onTap: () => _copyIncident(context, incident),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF527326),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Text(
                          'Copier les informations techniques',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _copyIncident(BuildContext context, AppIncident incident) async {
  final diagnostic = incident.technicalSummary();
  try {
    await Clipboard.setData(ClipboardData(text: diagnostic));
  } catch (error, stackTrace) {
    AppLogger.warning(
      'Clipboard unavailable; showing selectable incident diagnostic',
      error: error,
      stackTrace: stackTrace,
    );
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Informations techniques'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 420),
          child: SingleChildScrollView(child: SelectableText(diagnostic)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
    return;
  }
  if (!context.mounted) return;
  ScaffoldMessenger.maybeOf(
    context,
  )?.showSnackBar(const SnackBar(content: Text('Diagnostic copié.')));
}
