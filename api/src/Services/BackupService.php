<?php
declare(strict_types=1);

namespace Ayivonpome\Services;

use Ayivonpome\Config\Env;

final class BackupService
{
    public function writeJson(string $familyId, array $payload): string
    {
        $dir = rtrim(Env::get('BACKUP_PATH', __DIR__ . '/../../storage/backups'), '/');
        if (!is_dir($dir)) {
            mkdir($dir, 0755, true);
        }
        $file = $dir . '/family-' . preg_replace('/[^a-zA-Z0-9_-]/', '', $familyId) . '-' . gmdate('Ymd-His') . '.json';
        file_put_contents($file, json_encode($payload, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
        return basename($file);
    }
}

