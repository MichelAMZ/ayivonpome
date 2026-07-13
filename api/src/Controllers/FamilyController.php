<?php
declare(strict_types=1);

namespace Ayivonpome\Controllers;

use Ayivonpome\Repositories\FamilyRepository;
use Ayivonpome\Utils\JsonResponse;
use Ayivonpome\Utils\Request;

final class FamilyController
{
    public function index(): void
    {
        JsonResponse::success((new FamilyRepository())->all());
    }

    public function show(string $id): void
    {
        $family = (new FamilyRepository())->find($id);
        $family ? JsonResponse::success($family) : JsonResponse::error('NOT_FOUND', 'Famille introuvable.', 404);
    }

    public function save(Request $request): void
    {
        JsonResponse::success((new FamilyRepository())->upsert($request->json()), '', 201);
    }
}

