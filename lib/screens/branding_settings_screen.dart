import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/branding_settings.dart';
import '../providers/auth_provider.dart';
import '../providers/branding_provider.dart';
import '../providers/family_tree_provider.dart';
import '../providers/members_count_provider.dart';
import '../services/branding_service.dart';
import '../services/web_favicon_updater.dart';
import '../widgets/logo_position_selector.dart';
import '../widgets/logo_preview.dart';
import '../widgets/logo_size_selector.dart';
import '../widgets/logo_upload_card.dart';

class BrandingSettingsScreen extends ConsumerStatefulWidget {
  const BrandingSettingsScreen({super.key});

  @override
  ConsumerState<BrandingSettingsScreen> createState() =>
      _BrandingSettingsScreenState();
}

class _BrandingSettingsScreenState
    extends ConsumerState<BrandingSettingsScreen> {
  BrandingSettings? _draft;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(familyTreeProvider).value;
    final auth = ref.watch(authSessionProvider);
    final l10n = AppLocalizations.of(context);
    if (data == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.session?.canManageBranding != true) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.familyLogo)),
        body: Center(child: Text(l10n.brandingPermissionRequired)),
      );
    }

    final settings = _draft ?? data.appSettings.branding;
    final title = data.appSettings.applicationTitle.trim().isEmpty
        ? l10n.appTitle
        : data.appSettings.applicationTitle.trim();
    final membersCount = ref.watch(membersCountProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.familyLogo)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            l10n.visualIdentity,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          LogoPreview(
            settings: settings,
            title: title,
            membersCount: membersCount,
          ),
          const SizedBox(height: 12),
          LogoUploadCard(
            fileName: settings.logoFileName,
            onUpload: () => _pickLogo(settings),
            onDelete: () => _setDraft(
              ref
                  .read(brandingServiceProvider)
                  .deleteCustomLogo(
                    current: settings,
                    updatedBy: auth.session?.familyCode ?? '',
                  ),
            ),
            onRestore: () => _setDraft(
              ref
                  .read(brandingServiceProvider)
                  .restoreDefault(
                    current: settings,
                    updatedBy: auth.session?.familyCode ?? '',
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: settings.logoEnabled,
                    title: Text(l10n.showLogo),
                    onChanged: (value) => _setDraft(
                      settings.copyWith(
                        logoEnabled: value,
                        updatedAt: DateTime.now().toIso8601String(),
                        updatedBy: auth.session?.familyCode ?? '',
                      ),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: settings.useAsFavicon,
                    title: Text(l10n.useLogoAsFavicon),
                    onChanged: (value) => _setDraft(
                      settings.copyWith(
                        useAsFavicon: value,
                        faviconUrl: value ? settings.effectiveLogoUrl : '',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.logoPosition),
                  const SizedBox(height: 8),
                  LogoPositionSelector(
                    value: settings.logoPosition,
                    onChanged: (value) =>
                        _setDraft(settings.copyWith(logoPosition: value)),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.logoSize),
                  LogoSizeSelector(
                    desktop: settings.logoWidthDesktop,
                    tablet: settings.logoWidthTablet,
                    mobile: settings.logoWidthMobile,
                    onDesktopChanged: (value) =>
                        _setDraft(settings.copyWith(logoWidthDesktop: value)),
                    onTabletChanged: (value) =>
                        _setDraft(settings.copyWith(logoWidthTablet: value)),
                    onMobileChanged: (value) =>
                        _setDraft(settings.copyWith(logoWidthMobile: value)),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: settings.logoShape,
                    decoration: InputDecoration(labelText: l10n.logoShape),
                    items: const [
                      DropdownMenuItem(value: 'none', child: Text('Libre')),
                      DropdownMenuItem(value: 'circle', child: Text('Cercle')),
                      DropdownMenuItem(
                        value: 'rounded',
                        child: Text('Arrondi'),
                      ),
                    ],
                    onChanged: (value) =>
                        _setDraft(settings.copyWith(logoShape: value)),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: settings.memberCountDisplayMode,
                    decoration: InputDecoration(
                      labelText: l10n.showMemberCountOnLogo,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'onLogo',
                        child: Text('Sur le logo'),
                      ),
                      DropdownMenuItem(
                        value: 'superscriptTitle',
                        child: Text('Près du titre'),
                      ),
                      DropdownMenuItem(
                        value: 'bottomBar',
                        child: Text('BottomBar'),
                      ),
                      DropdownMenuItem(value: 'hidden', child: Text('Masqué')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      _setDraft(
                        ref
                            .read(brandingServiceProvider)
                            .updateSettings(
                              current: settings,
                              memberCountDisplayMode: value,
                              updatedBy: auth.session?.familyCode ?? '',
                            ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              TextButton(
                onPressed: _saving ? null : () => setState(() => _draft = null),
                child: Text(l10n.cancel),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: _saving
                    ? null
                    : () => _setDraft(
                        ref
                            .read(brandingServiceProvider)
                            .restoreDefault(
                              current: settings,
                              updatedBy: auth.session?.familyCode ?? '',
                            ),
                      ),
                child: Text(l10n.restoreDefaultLogo),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: _saving ? null : () => _save(settings),
                child: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickLogo(BrandingSettings settings) async {
    final l10n = AppLocalizations.of(context);
    final auth = ref.read(authSessionProvider);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'svg'],
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return;
    try {
      _setDraft(
        ref
            .read(brandingServiceProvider)
            .importLogo(
              current: settings,
              bytes: bytes,
              fileName: file.name,
              mimeType: _mimeType(file.extension),
              updatedBy: auth.session?.familyCode ?? '',
            ),
      );
    } on BrandingException catch (error) {
      _showError(
        error.code == 'logoFileTooLarge'
            ? l10n.logoFileTooLarge
            : l10n.invalidLogoFile,
      );
    }
  }

  Future<void> _save(BrandingSettings settings) async {
    final data = ref.read(familyTreeProvider).value;
    if (data == null) return;
    final auth = ref.read(authSessionProvider);
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(familyTreeProvider.notifier)
          .updateAppSettings(
            data.appSettings.copyWith(branding: settings),
            actorRole: auth.session?.role ?? 'viewer',
            adminId: auth.session?.familyCode ?? '',
          );
      if (settings.useAsFavicon) {
        updateWebFavicon(
          settings.faviconUrl.isEmpty
              ? settings.effectiveLogoUrl
              : settings.faviconUrl,
        );
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
        _draft = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.logoUpdated)));
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError(error.toString());
    }
  }

  void _setDraft(BrandingSettings settings) {
    setState(() => _draft = settings);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _mimeType(String? extension) {
    return switch ((extension ?? '').toLowerCase()) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      'svg' => 'image/svg+xml',
      _ => '',
    };
  }
}
