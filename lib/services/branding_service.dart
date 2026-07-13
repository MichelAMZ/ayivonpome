import 'dart:convert';
import 'dart:typed_data';

import '../models/branding_settings.dart';

class BrandingService {
  const BrandingService();

  static const maxLogoBytes = 5 * 1024 * 1024;
  static const allowedMimeTypes = {
    'image/png',
    'image/jpeg',
    'image/webp',
    'image/svg+xml',
  };

  BrandingSettings importLogo({
    required BrandingSettings current,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String updatedBy,
  }) {
    validateLogo(bytes: bytes, mimeType: mimeType);
    final encoded = base64Encode(bytes);
    final normalizedMime = mimeType.trim().isEmpty
        ? _mimeFromName(fileName)
        : mimeType.trim();
    return current.copyWith(
      logoEnabled: true,
      logoUrl: 'data:$normalizedMime;base64,$encoded',
      cachedLogoUrl: 'data:$normalizedMime;base64,$encoded',
      logoFileName: fileName,
      logoMimeType: normalizedMime,
      logoVersion: current.logoVersion + 1,
      updatedAt: DateTime.now().toIso8601String(),
      updatedBy: updatedBy,
    );
  }

  BrandingSettings updateSettings({
    required BrandingSettings current,
    bool? logoEnabled,
    double? logoWidthDesktop,
    double? logoWidthTablet,
    double? logoWidthMobile,
    String? logoPosition,
    String? logoFit,
    String? logoShape,
    String? memberCountDisplayMode,
    bool? useAsFavicon,
    String? updatedBy,
  }) {
    return current.copyWith(
      logoEnabled: logoEnabled,
      logoWidthDesktop: logoWidthDesktop,
      logoWidthTablet: logoWidthTablet,
      logoWidthMobile: logoWidthMobile,
      logoPosition: logoPosition,
      logoFit: logoFit,
      logoShape: logoShape,
      showMemberCountOnLogo: memberCountDisplayMode == null
          ? null
          : memberCountDisplayMode == 'onLogo',
      memberCountDisplayMode: memberCountDisplayMode,
      useAsFavicon: useAsFavicon,
      faviconUrl: useAsFavicon == true ? current.effectiveLogoUrl : '',
      updatedAt: DateTime.now().toIso8601String(),
      updatedBy: updatedBy ?? current.updatedBy,
    );
  }

  BrandingSettings deleteCustomLogo({
    required BrandingSettings current,
    required String updatedBy,
  }) {
    return current.copyWith(
      logoUrl: '',
      cachedLogoUrl: '',
      logoFileName: '',
      logoMimeType: '',
      useAsFavicon: false,
      faviconUrl: '',
      logoVersion: current.logoVersion + 1,
      updatedAt: DateTime.now().toIso8601String(),
      updatedBy: updatedBy,
    );
  }

  BrandingSettings restoreDefault({
    required BrandingSettings current,
    required String updatedBy,
  }) {
    return current.restoreDefault(
      updatedAt: DateTime.now().toIso8601String(),
      updatedBy: updatedBy,
    );
  }

  void validateLogo({required Uint8List bytes, required String mimeType}) {
    if (bytes.isEmpty) {
      throw const BrandingException('invalidLogoFile');
    }
    if (bytes.length > maxLogoBytes) {
      throw const BrandingException('logoFileTooLarge');
    }
    final normalized = mimeType.trim().toLowerCase();
    if (normalized.isNotEmpty && !allowedMimeTypes.contains(normalized)) {
      throw const BrandingException('invalidLogoFile');
    }
  }

  String _mimeFromName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    return 'application/octet-stream';
  }
}

class BrandingException implements Exception {
  const BrandingException(this.code);

  final String code;

  @override
  String toString() => code;
}
