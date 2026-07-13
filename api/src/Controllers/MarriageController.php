<?php
declare(strict_types=1);

namespace Ayivonpome\Controllers;

use Ayivonpome\Repositories\MarriageRepository;
use Ayivonpome\Utils\JsonResponse;
use Ayivonpome\Utils\Request;

final class MarriageController
{
    public function index(Request $request, array $session): void
    {
        JsonResponse::success((new MarriageRepository())->all($request->query('familyId', $session['family_id'] ?? '')));
    }
}

