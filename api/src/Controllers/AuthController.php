<?php
declare(strict_types=1);

namespace Ayivonpome\Controllers;

use Ayivonpome\Services\AuthService;
use Ayivonpome\Utils\JsonResponse;
use Ayivonpome\Utils\Request;

final class AuthController
{
    public function code(Request $request, string $type): void
    {
        $payload = $request->json();
        $code = (string) ($payload['code'] ?? '');
        if ($code === '') {
            JsonResponse::error('VALIDATION_ERROR', 'Code requis.', 422, ['code' => 'required']);
        }
        $session = (new AuthService())->authenticate($type, $code);
        if (!$session) {
            JsonResponse::error('INVALID_CODE', 'Code invalide.', 401);
        }
        JsonResponse::success($session);
    }

    public function session(array $session): void
    {
        JsonResponse::success($session);
    }
}

