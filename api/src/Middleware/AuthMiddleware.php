<?php
declare(strict_types=1);

namespace Ayivonpome\Middleware;

use Ayivonpome\Repositories\AdminRepository;
use Ayivonpome\Utils\JsonResponse;
use Ayivonpome\Utils\Request;

final class AuthMiddleware
{
    public static function requireSession(Request $request): array
    {
        $token = $request->bearerToken();
        if ($token === '') {
            JsonResponse::error('UNAUTHENTICATED', 'Session requise.', 401);
        }
        $session = (new AdminRepository())->findSession($token);
        if (!$session) {
            JsonResponse::error('UNAUTHENTICATED', 'Session invalide ou expirée.', 401);
        }
        return $session;
    }
}

