<?php
declare(strict_types=1);

require dirname(__DIR__) . '/src/Config/Env.php';
require dirname(__DIR__) . '/src/Config/Database.php';
require dirname(__DIR__) . '/src/Repositories/PersonRepository.php';

use Ayivonpome\Config\Database;
use Ayivonpome\Config\Env;
use Ayivonpome\Repositories\PersonRepository;

Env::load(dirname(__DIR__) . '/.env');

$codes = [
    ['label' => 'Code accès famille principal', 'code_type' => 'family_access', 'role' => 'viewer', 'env' => 'INITIAL_FAMILY_CODE'],
    ['label' => 'Code Admin KPI initial', 'code_type' => 'admin_kpi', 'role' => 'admin', 'env' => 'INITIAL_ADMIN_CODE'],
    ['label' => 'Code récupération Super Admin initial', 'code_type' => 'super_admin_recovery', 'role' => 'super_admin', 'env' => 'INITIAL_RECOVERY_CODE'],
];

$familyId = Env::get('INITIAL_FAMILY_ID', 'family-ayivon');
$db = Database::connection();

foreach ($codes as $item) {
    $plain = Env::get($item['env']);
    if ($plain === '') {
        fwrite(STDERR, "Missing {$item['env']} in .env\n");
        continue;
    }
    $stmt = $db->prepare('INSERT INTO access_codes (id, family_id, label, code_hash, code_type, role, created_by, updated_by) VALUES (:id, :family_id, :label, :code_hash, :code_type, :role, :created_by, :updated_by)');
    $stmt->execute([
        'id' => PersonRepository::uuid(),
        'family_id' => $familyId,
        'label' => $item['label'],
        'code_hash' => password_hash($plain, PASSWORD_DEFAULT),
        'code_type' => $item['code_type'],
        'role' => $item['role'],
        'created_by' => 'seed',
        'updated_by' => 'seed',
    ]);
    echo "Seeded {$item['code_type']}\n";
}

