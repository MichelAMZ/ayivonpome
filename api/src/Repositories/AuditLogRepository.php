<?php
declare(strict_types=1);

namespace Ayivonpome\Repositories;

use Ayivonpome\Config\Database;

final class AuditLogRepository
{
    public function add(string $familyId, string $action, string $entityType, string $entityId, string $actor = '', array $payload = []): void
    {
        $stmt = Database::connection()->prepare('INSERT INTO audit_logs (id, family_id, action, entity_type, entity_id, actor_id, payload_json, created_at) VALUES (:id, :family_id, :action, :entity_type, :entity_id, :actor_id, :payload_json, NOW())');
        $stmt->execute([
            'id' => PersonRepository::uuid(),
            'family_id' => $familyId,
            'action' => $action,
            'entity_type' => $entityType,
            'entity_id' => $entityId,
            'actor_id' => $actor,
            'payload_json' => json_encode($payload, JSON_UNESCAPED_UNICODE),
        ]);
    }
}

