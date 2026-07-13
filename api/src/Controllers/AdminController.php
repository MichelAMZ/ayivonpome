<?php
declare(strict_types=1);

namespace Ayivonpome\Controllers;

use Ayivonpome\Utils\JsonResponse;

final class AdminController
{
    public function kpi(array $session): void
    {
        JsonResponse::success([
            'familyId' => $session['family_id'] ?? '',
            'status' => 'ready',
            'message' => 'KPI endpoint ready. Connect aggregate SQL queries in the next migration step.',
        ]);
    }
}
