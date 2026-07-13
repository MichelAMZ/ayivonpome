<?php
declare(strict_types=1);

namespace Ayivonpome\Repositories;

use Ayivonpome\Config\Database;
use PDO;

final class AdminRepository
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::connection();
    }

    public function findValidCode(string $codeType, string $plainCode): ?array
    {
        $stmt = $this->db->prepare('SELECT * FROM access_codes WHERE code_type = :type AND enabled = 1 AND deleted_at IS NULL AND (expires_at IS NULL OR expires_at > NOW())');
        $stmt->execute(['type' => $codeType]);
        foreach ($stmt->fetchAll() as $row) {
            if (password_verify($plainCode, $row['code_hash'])) {
                return $row;
            }
        }
        return null;
    }

    public function createSession(array $code): array
    {
        $token = bin2hex(random_bytes(32));
        $expiresAt = gmdate('Y-m-d H:i:s', time() + 60 * 60 * 8);
        $stmt = $this->db->prepare('INSERT INTO api_sessions (id, token_hash, family_id, role, expires_at, created_at) VALUES (:id, :token_hash, :family_id, :role, :expires_at, NOW())');
        $stmt->execute([
            'id' => PersonRepository::uuid(),
            'token_hash' => hash('sha256', $token),
            'family_id' => $code['family_id'],
            'role' => $code['role'],
            'expires_at' => $expiresAt,
        ]);
        return [
            'token' => $token,
            'familyId' => $code['family_id'],
            'role' => $code['role'],
            'expiresAt' => $expiresAt,
            'permissions' => self::permissionsFor($code['role']),
        ];
    }

    public function findSession(string $token): ?array
    {
        $stmt = $this->db->prepare('SELECT * FROM api_sessions WHERE token_hash = :hash AND expires_at > NOW()');
        $stmt->execute(['hash' => hash('sha256', $token)]);
        $row = $stmt->fetch();
        return $row ?: null;
    }

    private static function permissionsFor(string $role): array
    {
        return match ($role) {
            'super_admin' => ['read', 'write', 'admin', 'super_admin'],
            'admin' => ['read', 'write', 'admin'],
            'editor' => ['read', 'write'],
            default => ['read'],
        };
    }
}

