<?php
declare(strict_types=1);

namespace Ayivonpome\Controllers;

use Ayivonpome\Repositories\PersonRepository;
use Ayivonpome\Services\AuditService;
use Ayivonpome\Services\ValidationService;
use Ayivonpome\Utils\JsonResponse;
use Ayivonpome\Utils\Request;

final class PersonController
{
    public function index(Request $request, array $session): void
    {
        $familyId = $request->query('familyId', $session['family_id'] ?? '');
        JsonResponse::success((new PersonRepository())->all($familyId));
    }

    public function show(string $id): void
    {
        $person = (new PersonRepository())->find($id);
        $person ? JsonResponse::success($person) : JsonResponse::error('NOT_FOUND', 'Personne introuvable.', 404);
    }

    public function save(Request $request, array $session): void
    {
        $payload = $request->json();
        $errors = (new ValidationService())->person($payload);
        if ($errors) {
            JsonResponse::error('VALIDATION_ERROR', 'Données invalides.', 422, $errors);
        }
        $person = (new PersonRepository())->upsert($payload);
        (new AuditService())->record($person['family_id'], 'person_saved', 'person', $person['id'], $session['id'] ?? '', $payload);
        JsonResponse::success($person, '', 201);
    }

    public function delete(string $id, array $session): void
    {
        (new PersonRepository())->delete($id, $session['id'] ?? '');
        JsonResponse::success(['id' => $id]);
    }

    public function linkedTree(string $id): void
    {
        JsonResponse::success((new PersonRepository())->linkedTree($id));
    }
}

