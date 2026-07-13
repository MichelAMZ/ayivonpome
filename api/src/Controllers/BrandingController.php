<?php
declare(strict_types=1);

namespace Ayivonpome\Controllers;

use Ayivonpome\Config\Env;
use Ayivonpome\Repositories\AppSettingsRepository;
use Ayivonpome\Repositories\PersonRepository;
use Ayivonpome\Services\AuditService;
use Ayivonpome\Utils\JsonResponse;
use Ayivonpome\Utils\Request;

final class BrandingController
{
    private const KEY = 'branding';

    public function show(array $session): void
    {
        JsonResponse::success($this->repository()->get($session['family_id'], self::KEY, $this->defaults()));
    }

    public function update(Request $request, array $session): void
    {
        $payload = array_merge($this->defaults(), $request->json());
        $payload['updatedAt'] = gmdate('c');
        $payload['updatedBy'] = $session['id'] ?? '';
        $saved = $this->repository()->put($session['family_id'], self::KEY, $payload, $session['id'] ?? '');
        (new AuditService())->record($session['family_id'], 'branding_settings_updated', 'app_settings', self::KEY, $session['id'] ?? '', $saved);
        JsonResponse::success($saved);
    }

    public function uploadLogo(array $session): void
    {
        if (!isset($_FILES['logo'])) {
            JsonResponse::error('VALIDATION_ERROR', 'Logo requis.', 422, ['logo' => 'required']);
        }
        $file = $_FILES['logo'];
        if (($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
            JsonResponse::error('INVALID_LOGO_FILE', 'Upload invalide.', 422);
        }
        if (($file['size'] ?? 0) > (int) Env::get('MAX_UPLOAD_BYTES', '5242880')) {
            JsonResponse::error('LOGO_FILE_TOO_LARGE', 'Fichier trop volumineux.', 422);
        }
        $mime = mime_content_type($file['tmp_name']);
        $allowed = ['image/png' => 'png', 'image/jpeg' => 'jpg', 'image/webp' => 'webp', 'image/svg+xml' => 'svg'];
        if (!isset($allowed[$mime])) {
            JsonResponse::error('INVALID_LOGO_FILE', 'Format non autorisé.', 422);
        }
        $familyId = preg_replace('/[^a-zA-Z0-9_-]/', '', $session['family_id']);
        $uploadRoot = rtrim(Env::get('UPLOAD_PATH', dirname(__DIR__, 2) . '/storage/uploads'), '/');
        $dir = $uploadRoot . '/branding/' . $familyId;
        if (!is_dir($dir)) {
            mkdir($dir, 0755, true);
        }
        $name = 'logo-' . bin2hex(random_bytes(8)) . '.' . $allowed[$mime];
        $target = $dir . '/' . $name;
        if (!move_uploaded_file($file['tmp_name'], $target)) {
            JsonResponse::error('UPLOAD_FAILED', 'Impossible de stocker le logo.', 500);
        }
        $url = '/uploads/branding/' . $familyId . '/' . $name;
        $settings = $this->repository()->get($session['family_id'], self::KEY, $this->defaults());
        $settings['logoEnabled'] = true;
        $settings['logoUrl'] = $url;
        $settings['logoFileName'] = $name;
        $settings['logoMimeType'] = $mime;
        $settings['logoVersion'] = (int) ($settings['logoVersion'] ?? 1) + 1;
        $settings['updatedAt'] = gmdate('c');
        $settings['updatedBy'] = $session['id'] ?? '';
        $saved = $this->repository()->put($session['family_id'], self::KEY, $settings, $session['id'] ?? '');
        (new AuditService())->record($session['family_id'], 'branding_logo_uploaded', 'app_settings', self::KEY, $session['id'] ?? '', ['newLogo' => $url]);
        JsonResponse::success($saved, '', 201);
    }

    public function deleteLogo(array $session): void
    {
        $settings = $this->repository()->get($session['family_id'], self::KEY, $this->defaults());
        $old = $settings['logoUrl'] ?? '';
        $settings['logoUrl'] = '';
        $settings['logoFileName'] = '';
        $settings['logoMimeType'] = '';
        $settings['useAsFavicon'] = false;
        $settings['faviconUrl'] = '';
        $settings['logoVersion'] = (int) ($settings['logoVersion'] ?? 1) + 1;
        $saved = $this->repository()->put($session['family_id'], self::KEY, $settings, $session['id'] ?? '');
        (new AuditService())->record($session['family_id'], 'branding_logo_deleted', 'app_settings', self::KEY, $session['id'] ?? '', ['oldLogo' => $old]);
        JsonResponse::success($saved);
    }

    public function restoreDefault(array $session): void
    {
        $settings = $this->defaults();
        $settings['logoVersion'] = (int) ($this->repository()->get($session['family_id'], self::KEY, [])['logoVersion'] ?? 1) + 1;
        $settings['updatedAt'] = gmdate('c');
        $settings['updatedBy'] = $session['id'] ?? '';
        $saved = $this->repository()->put($session['family_id'], self::KEY, $settings, $session['id'] ?? '');
        (new AuditService())->record($session['family_id'], 'branding_logo_restored', 'app_settings', self::KEY, $session['id'] ?? '', $saved);
        JsonResponse::success($saved);
    }

    public function favicon(Request $request, array $session): void
    {
        $settings = $this->repository()->get($session['family_id'], self::KEY, $this->defaults());
        $settings['useAsFavicon'] = true;
        $settings['faviconUrl'] = $request->json()['faviconUrl'] ?? ($settings['logoUrl'] ?? '');
        $saved = $this->repository()->put($session['family_id'], self::KEY, $settings, $session['id'] ?? '');
        (new AuditService())->record($session['family_id'], 'favicon_updated', 'app_settings', self::KEY, $session['id'] ?? '', $saved);
        JsonResponse::success($saved);
    }

    private function repository(): AppSettingsRepository
    {
        return new AppSettingsRepository();
    }

    private function defaults(): array
    {
        return [
            'logoEnabled' => true,
            'logoUrl' => '',
            'defaultLogoUrl' => '/assets/images/family_logo.png',
            'logoFileName' => '',
            'logoMimeType' => '',
            'logoWidthDesktop' => 140,
            'logoWidthTablet' => 92,
            'logoWidthMobile' => 52,
            'logoPosition' => 'leftOfTitle',
            'logoFit' => 'contain',
            'logoShape' => 'none',
            'showMemberCountOnLogo' => true,
            'memberCountDisplayMode' => 'onLogo',
            'useAsFavicon' => false,
            'faviconUrl' => '',
            'logoVersion' => 1,
        ];
    }
}

