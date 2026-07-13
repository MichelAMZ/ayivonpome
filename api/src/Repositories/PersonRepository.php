<?php
declare(strict_types=1);

namespace Ayivonpome\Repositories;

use Ayivonpome\Config\Database;
use PDO;

final class PersonRepository
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::connection();
    }

    public function all(string $familyId): array
    {
        $stmt = $this->db->prepare('SELECT * FROM people WHERE family_id = :family_id AND deleted_at IS NULL ORDER BY last_name, first_name');
        $stmt->execute(['family_id' => $familyId]);
        return $stmt->fetchAll();
    }

    public function find(string $id): ?array
    {
        $stmt = $this->db->prepare('SELECT * FROM people WHERE id = :id AND deleted_at IS NULL');
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch();
        return $row ?: null;
    }

    public function upsert(array $data): array
    {
        $id = $data['id'] ?? self::uuid();
        $existing = $this->find($id);
        $payload = [
            'id' => $id,
            'family_id' => $data['familyId'] ?? $data['family_id'] ?? '',
            'origin_family_id' => $data['originFamilyId'] ?? $data['origin_family_id'] ?? null,
            'first_name' => $data['firstName'] ?? $data['first_name'] ?? '',
            'last_name' => $data['lastName'] ?? $data['last_name'] ?? '',
            'birth_last_name' => $data['birthLastName'] ?? $data['birth_last_name'] ?? '',
            'gender' => self::normalizeGender($data['gender'] ?? 'unknown'),
            'birth_date' => self::emptyToNull($data['birthDate'] ?? $data['birth_date'] ?? null),
            'birth_place' => $data['birthPlace'] ?? $data['birth_place'] ?? '',
            'death_date' => self::emptyToNull($data['deathDate'] ?? $data['death_date'] ?? null),
            'death_place' => $data['deathPlace'] ?? $data['death_place'] ?? '',
            'burial_place' => $data['burialPlace'] ?? $data['burial_place'] ?? '',
            'current_address' => $data['currentAddress'] ?? $data['current_address'] ?? '',
            'current_city' => $data['currentCity'] ?? $data['current_city'] ?? '',
            'current_region' => $data['currentRegion'] ?? $data['current_region'] ?? '',
            'current_country' => $data['currentCountry'] ?? $data['current_country'] ?? '',
            'latitude' => $data['latitude'] ?? null,
            'longitude' => $data['longitude'] ?? null,
            'email' => $data['email'] ?? '',
            'phone_number' => $data['phoneNumber'] ?? $data['phone_number'] ?? '',
            'whatsapp_number' => $data['whatsappNumber'] ?? $data['whatsapp_number'] ?? '',
            'photo_url' => $data['photoUrl'] ?? $data['photo_url'] ?? ($data['photo'] ?? ''),
            'notes' => $data['notes'] ?? '',
            'privacy_json' => json_encode($data['privacy'] ?? [], JSON_UNESCAPED_UNICODE),
            'linked_tree_enabled' => !empty($data['linkedTreeEnabled']) ? 1 : 0,
            'updated_by' => $data['updatedBy'] ?? $data['updated_by'] ?? '',
        ];
        if ($existing) {
            $sql = 'UPDATE people SET family_id=:family_id, origin_family_id=:origin_family_id, first_name=:first_name, last_name=:last_name, birth_last_name=:birth_last_name, gender=:gender, birth_date=:birth_date, birth_place=:birth_place, death_date=:death_date, death_place=:death_place, burial_place=:burial_place, current_address=:current_address, current_city=:current_city, current_region=:current_region, current_country=:current_country, latitude=:latitude, longitude=:longitude, email=:email, phone_number=:phone_number, whatsapp_number=:whatsapp_number, photo_url=:photo_url, notes=:notes, privacy_json=:privacy_json, linked_tree_enabled=:linked_tree_enabled, updated_by=:updated_by, updated_at=NOW(), version=version+1 WHERE id=:id';
            $this->db->prepare($sql)->execute($payload);
        } else {
            $payload['created_by'] = $payload['updated_by'];
            $sql = 'INSERT INTO people (id, family_id, origin_family_id, first_name, last_name, birth_last_name, gender, birth_date, birth_place, death_date, death_place, burial_place, current_address, current_city, current_region, current_country, latitude, longitude, email, phone_number, whatsapp_number, photo_url, notes, privacy_json, linked_tree_enabled, created_by, updated_by) VALUES (:id, :family_id, :origin_family_id, :first_name, :last_name, :birth_last_name, :gender, :birth_date, :birth_place, :death_date, :death_place, :burial_place, :current_address, :current_city, :current_region, :current_country, :latitude, :longitude, :email, :phone_number, :whatsapp_number, :photo_url, :notes, :privacy_json, :linked_tree_enabled, :created_by, :updated_by)';
            $this->db->prepare($sql)->execute($payload);
        }
        return $this->find($id) ?? [];
    }

    public function delete(string $id, string $actor = ''): void
    {
        $stmt = $this->db->prepare('UPDATE people SET deleted_at = NOW(), updated_by = :actor, version = version + 1 WHERE id = :id');
        $stmt->execute(['id' => $id, 'actor' => $actor]);
    }

    public function linkedTree(string $personId): array
    {
        $stmt = $this->db->prepare('SELECT p.* FROM people p WHERE p.deleted_at IS NULL AND (p.id = :id OR p.family_id = (SELECT origin_family_id FROM people WHERE id = :id2))');
        $stmt->execute(['id' => $personId, 'id2' => $personId]);
        return $stmt->fetchAll();
    }

    public static function uuid(): string
    {
        $bytes = random_bytes(16);
        $bytes[6] = chr((ord($bytes[6]) & 0x0f) | 0x40);
        $bytes[8] = chr((ord($bytes[8]) & 0x3f) | 0x80);
        return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($bytes), 4));
    }

    private static function emptyToNull(mixed $value): mixed
    {
        return $value === '' ? null : $value;
    }

    private static function normalizeGender(string $gender): string
    {
        $value = strtolower(trim($gender));
        return match ($value) {
            'm', 'male', 'homme' => 'male',
            'f', 'female', 'femme' => 'female',
            default => 'unknown',
        };
    }
}

