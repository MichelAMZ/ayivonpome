<?php
declare(strict_types=1);

namespace Ayivonpome\Repositories;

use Ayivonpome\Config\Database;

final class MarriageRepository
{
    public function all(string $familyId): array
    {
        $stmt = Database::connection()->prepare('SELECT * FROM marriage_relations WHERE family_id = :family_id AND deleted_at IS NULL');
        $stmt->execute(['family_id' => $familyId]);
        return $stmt->fetchAll();
    }
}

