import 'dart:typed_data';

import 'package:ayivonpome/models/branding_settings.dart';
import 'package:ayivonpome/services/branding_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrandingService', () {
    test('imports a valid logo as cached data URL and increments version', () {
      const service = BrandingService();

      final next = service.importLogo(
        current: const BrandingSettings(logoVersion: 2),
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'logo.webp',
        mimeType: 'image/webp',
        updatedBy: 'admin',
      );

      expect(next.logoEnabled, isTrue);
      expect(next.logoUrl, startsWith('data:image/webp;base64,'));
      expect(next.cachedLogoUrl, next.logoUrl);
      expect(next.logoFileName, 'logo.webp');
      expect(next.logoMimeType, 'image/webp');
      expect(next.logoVersion, 3);
      expect(next.updatedBy, 'admin');
    });

    test('rejects empty or unsupported logo files', () {
      const service = BrandingService();

      expect(
        () => service.importLogo(
          current: const BrandingSettings(),
          bytes: Uint8List(0),
          fileName: 'logo.exe',
          mimeType: 'application/octet-stream',
          updatedBy: 'admin',
        ),
        throwsA(isA<BrandingException>()),
      );

      expect(
        () => service.importLogo(
          current: const BrandingSettings(),
          bytes: Uint8List.fromList([1]),
          fileName: 'logo.exe',
          mimeType: 'application/octet-stream',
          updatedBy: 'admin',
        ),
        throwsA(isA<BrandingException>()),
      );
    });

    test('restores default logo without deleting the system default', () {
      const service = BrandingService();

      final next = service.restoreDefault(
        current: const BrandingSettings(
          logoUrl: 'data:image/png;base64,abc',
          logoVersion: 4,
        ),
        updatedBy: 'superAdmin',
      );

      expect(next.logoUrl, isEmpty);
      expect(next.defaultLogoUrl, 'assets/images/family_logo.png');
      expect(next.logoVersion, 5);
      expect(next.updatedBy, 'superAdmin');
    });
  });
}
