<?php
declare(strict_types=1);

namespace Ayivonpome\Controllers;

use Ayivonpome\Repositories\RelationshipRepository;
use Ayivonpome\Utils\JsonResponse;
use Ayivonpome\Utils\Request;

final class RelationshipController
{
    public function index(Request $request, array $session): void
    {
        JsonResponse::success((new RelationshipRepository())->all($request->query('familyId', $session['family_id'] ?? '')));
    }
}

