<?php
declare(strict_types=1);

namespace Ayivonpome\Repositories;

use Ayivonpome\Config\Database;

final class RelationshipRepository
{
    public function all(string $familyId): array
    {
        $stmt = Database::connection()->prepare('SELECT * FROM parent_child_relations WHERE family_id = :family_id AND deleted_at IS NULL');
        $stmt->execute(['family_id' => $familyId]);
        return $stmt->fetchAll();
    }
}

