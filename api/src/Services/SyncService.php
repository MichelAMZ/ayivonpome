<?php
declare(strict_types=1);

namespace Ayivonpome\Services;

use Ayivonpome\Config\Database;
use Ayivonpome\Repositories\PersonRepository;
use Ayivonpome\Repositories\SyncRepository;

final class SyncService
{
    public function push(array $payload, string $familyId): array
    {
        $db = Database::connection();
        $db->beginTransaction();
        try {
            $results = [];
            $people = new PersonRepository();
            foreach ($payload['operations'] ?? [] as $operation) {
                if (($operation['entityType'] ?? '') === 'person') {
                    if (($operation['action'] ?? '') === 'delete') {
                        $people->delete((string) $operation['entityId']);
                    } else {
                        $results[] = $people->upsert($operation['payload'] ?? []);
                    }
                }
            }
            $db->commit();
            return [
                'applied' => count($results),
                'serverVersion' => (new SyncRepository())->serverVersion($familyId),
            ];
        } catch (\Throwable $error) {
            $db->rollBack();
            throw $error;
        }
    }

    public function pull(string $familyId): array
    {
        return [
            'people' => (new PersonRepository())->all($familyId),
            'serverVersion' => (new SyncRepository())->serverVersion($familyId),
        ];
    }
}

