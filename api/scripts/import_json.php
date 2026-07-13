<?php
declare(strict_types=1);

require dirname(__DIR__) . '/src/Config/Env.php';
require dirname(__DIR__) . '/src/Config/Database.php';
require dirname(__DIR__) . '/src/Repositories/PersonRepository.php';
require dirname(__DIR__) . '/src/Repositories/FamilyRepository.php';

use Ayivonpome\Config\Database;
use Ayivonpome\Config\Env;
use Ayivonpome\Repositories\FamilyRepository;
use Ayivonpome\Repositories\PersonRepository;

Env::load(dirname(__DIR__) . '/.env');

$path = $argv[1] ?? dirname(__DIR__, 2) . '/assets/data/family_tree.json';
if (!is_file($path)) {
    fwrite(STDERR, "JSON file not found: {$path}\n");
    exit(1);
}

$data = json_decode(file_get_contents($path) ?: '', true);
if (!is_array($data)) {
    fwrite(STDERR, "Invalid JSON\n");
    exit(1);
}

$db = Database::connection();
$db->beginTransaction();
$report = ['families' => 0, 'people' => 0, 'parent_child_relations' => 0, 'marriage_relations' => 0, 'errors' => []];

try {
    $families = $data['families'] ?? [];
    if (!$families) {
        $families = [['id' => 'family-ayivon', 'name' => $data['appSettings']['officialFamilyName'] ?? 'Famille AYIVON', 'code' => strtoupper($data['mainFamilyCode'] ?? 'AYIVON')]];
    }
    $familyRepository = new FamilyRepository();
    foreach ($families as $family) {
        $familyRepository->upsert($family + ['updatedBy' => 'json-import']);
        $report['families']++;
    }

    $defaultFamilyId = $families[0]['id'] ?? 'family-ayivon';
    $peopleRepository = new PersonRepository();
    foreach ($data['people'] ?? [] as $person) {
        $person['familyId'] = $person['familyId'] ?? $defaultFamilyId;
        $peopleRepository->upsert($person + ['updatedBy' => 'json-import']);
        $report['people']++;
    }

    foreach ($data['people'] ?? [] as $person) {
        $childId = $person['id'] ?? '';
        foreach ([['fatherId', 'father'], ['motherId', 'mother']] as [$field, $role]) {
            $parentId = $person[$field] ?? '';
            if ($childId === '' || $parentId === '') {
                continue;
            }
            $stmt = $db->prepare('INSERT IGNORE INTO parent_child_relations (id, family_id, parent_id, child_id, parent_role, relation_type, created_by, updated_by) VALUES (:id, :family_id, :parent_id, :child_id, :parent_role, :relation_type, :created_by, :updated_by)');
            $stmt->execute([
                'id' => PersonRepository::uuid(),
                'family_id' => $person['familyId'] ?? $defaultFamilyId,
                'parent_id' => $parentId,
                'child_id' => $childId,
                'parent_role' => $role,
                'relation_type' => 'unknown',
                'created_by' => 'json-import',
                'updated_by' => 'json-import',
            ]);
            $report['parent_child_relations']++;
        }
    }

    foreach ($data['marriageRelations'] ?? [] as $marriage) {
        $stmt = $db->prepare('INSERT IGNORE INTO marriage_relations (id, family_id, person_one_id, person_two_id, marriage_type, status, marriage_date, marriage_place, divorce_date, order_index, notes, created_by, updated_by) VALUES (:id, :family_id, :person_one_id, :person_two_id, :marriage_type, :status, :marriage_date, :marriage_place, :divorce_date, :order_index, :notes, :created_by, :updated_by)');
        $stmt->execute([
            'id' => $marriage['id'] ?? PersonRepository::uuid(),
            'family_id' => $marriage['familyId'] ?? $defaultFamilyId,
            'person_one_id' => $marriage['personId'] ?? '',
            'person_two_id' => $marriage['spouseId'] ?? '',
            'marriage_type' => $marriage['marriageType'] ?? 'unknown',
            'status' => $marriage['status'] ?? 'unknown',
            'marriage_date' => ($marriage['marriageDate'] ?? '') ?: null,
            'marriage_place' => $marriage['marriagePlace'] ?? '',
            'divorce_date' => ($marriage['divorceDate'] ?? '') ?: null,
            'order_index' => $marriage['order'] ?? 0,
            'notes' => $marriage['notes'] ?? '',
            'created_by' => 'json-import',
            'updated_by' => 'json-import',
        ]);
        $report['marriage_relations']++;
    }

    $db->commit();
    echo json_encode($report, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . PHP_EOL;
} catch (Throwable $error) {
    $db->rollBack();
    $report['errors'][] = $error->getMessage();
    fwrite(STDERR, json_encode($report, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . PHP_EOL);
    exit(1);
}

