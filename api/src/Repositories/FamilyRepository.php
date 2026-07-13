<?php
declare(strict_types=1);

namespace Ayivonpome\Repositories;

use Ayivonpome\Config\Database;
use PDO;

final class FamilyRepository
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::connection();
    }

    public function all(): array
    {
        return $this->db->query('SELECT * FROM families WHERE deleted_at IS NULL ORDER BY name')->fetchAll();
    }

    public function find(string $id): ?array
    {
        $stmt = $this->db->prepare('SELECT * FROM families WHERE id = :id AND deleted_at IS NULL');
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch();
        return $row ?: null;
    }

    public function upsert(array $data): array
    {
        $id = $data['id'] ?? PersonRepository::uuid();
        $payload = [
            'id' => $id,
            'name' => $data['name'] ?? '',
            'code' => $data['code'] ?? '',
            'parent_family_id' => $data['parentFamilyId'] ?? $data['parent_family_id'] ?? null,
            'updated_by' => $data['updatedBy'] ?? '',
        ];
        if ($this->find($id)) {
            $sql = 'UPDATE families SET name=:name, code=:code, parent_family_id=:parent_family_id, updated_by=:updated_by, updated_at=NOW(), version=version+1 WHERE id=:id';
            $this->db->prepare($sql)->execute($payload);
        } else {
            $payload['created_by'] = $payload['updated_by'];
            $sql = 'INSERT INTO families (id, name, code, parent_family_id, created_by, updated_by) VALUES (:id, :name, :code, :parent_family_id, :created_by, :updated_by)';
            $this->db->prepare($sql)->execute($payload);
        }
        return $this->find($id) ?? [];
    }
}

