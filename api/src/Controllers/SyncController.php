<?php
declare(strict_types=1);

namespace Ayivonpome\Controllers;

use Ayivonpome\Services\SyncService;
use Ayivonpome\Utils\JsonResponse;
use Ayivonpome\Utils\Request;

final class SyncController
{
    public function push(Request $request, array $session): void
    {
        $familyId = (string) (($request->json()['familyId'] ?? '') ?: ($session['family_id'] ?? ''));
        JsonResponse::success((new SyncService())->push($request->json(), $familyId));
    }

    public function pull(Request $request, array $session): void
    {
        $familyId = $request->query('familyId', $session['family_id'] ?? '');
        JsonResponse::success((new SyncService())->pull($familyId));
    }
}

