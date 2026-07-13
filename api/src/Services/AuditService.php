<?php
declare(strict_types=1);

namespace Ayivonpome\Services;

use Ayivonpome\Repositories\AuditLogRepository;

final class AuditService
{
    public function record(string $familyId, string $action, string $entityType, string $entityId, string $actor = '', array $payload = []): void
    {
        (new AuditLogRepository())->add($familyId, $action, $entityType, $entityId, $actor, $payload);
    }
}

