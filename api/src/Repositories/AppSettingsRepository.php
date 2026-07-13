<?php
declare(strict_types=1);

namespace Ayivonpome\Repositories;

use Ayivonpome\Config\Database;

final class AppSettingsRepository
{
    public function get(string $familyId, string $key, array $fallback = []): array
    {
        $stmt = Database::connection()->prepare('SELECT setting_value_json FROM app_settings WHERE family_id = :family_id AND setting_key = :setting_key AND deleted_at IS NULL ORDER BY updated_at DESC LIMIT 1');
        $stmt->execute(['family_id' => $familyId, 'setting_key' => $key]);
        $row = $stmt->fetch();
        if (!$row) return $fallback;
        $decoded = json_decode((string) $row['setting_value_json'], true);
        return is_array($decoded) ? $decoded : $fallback;
    }

    public function put(string $familyId, string $key, array $value, string $actor = ''): array
    {
        $existing = $this->get($familyId, $key, []);
        $payload = [
            'id' => PersonRepository::uuid(),
            'family_id' => $familyId,
            'setting_key' => $key,
            'setting_value_json' => json_encode($value, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            'updated_by' => $actor,
        ];
        if ($existing) {
            $stmt = Database::connection()->prepare('UPDATE app_settings SET setting_value_json = :setting_value_json, updated_by = :updated_by, updated_at = NOW(), version = version + 1 WHERE family_id = :family_id AND setting_key = :setting_key AND deleted_at IS NULL');
            $stmt->execute([
                'family_id' => $familyId,
                'setting_key' => $key,
                'setting_value_json' => $payload['setting_value_json'],
                'updated_by' => $actor,
            ]);
        } else {
            $stmt = Database::connection()->prepare('INSERT INTO app_settings (id, family_id, setting_key, setting_value_json, created_by, updated_by) VALUES (:id, :family_id, :setting_key, :setting_value_json, :updated_by, :updated_by)');
            $stmt->execute($payload);
        }
        return $value;
    }
}

