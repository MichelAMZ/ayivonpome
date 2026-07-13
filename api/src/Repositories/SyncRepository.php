<?php
declare(strict_types=1);

namespace Ayivonpome\Repositories;

use Ayivonpome\Config\Database;

final class SyncRepository
{
    public function serverVersion(string $familyId): int
    {
        $stmt = Database::connection()->prepare('SELECT COALESCE(MAX(version), 0) AS version FROM people WHERE family_id = :family_id');
        $stmt->execute(['family_id' => $familyId]);
        return (int) ($stmt->fetch()['version'] ?? 0);
    }
}

