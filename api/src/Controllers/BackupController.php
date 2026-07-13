<?php
declare(strict_types=1);

namespace Ayivonpome\Controllers;

use Ayivonpome\Repositories\FamilyRepository;
use Ayivonpome\Repositories\PersonRepository;
use Ayivonpome\Services\BackupService;
use Ayivonpome\Utils\JsonResponse;
use Ayivonpome\Utils\Request;

final class BackupController
{
    public function export(Request $request, string $familyId): void
    {
        $payload = [
            'families' => [(new FamilyRepository())->find($familyId)],
            'people' => (new PersonRepository())->all($familyId),
        ];
        JsonResponse::success($payload);
    }

    public function create(Request $request, array $session): void
    {
        $familyId = $request->query('familyId', $session['family_id'] ?? '');
        $payload = [
            'families' => [(new FamilyRepository())->find($familyId)],
            'people' => (new PersonRepository())->all($familyId),
        ];
        $file = (new BackupService())->writeJson($familyId, $payload);
        JsonResponse::success(['file' => $file], '', 201);
    }
}

