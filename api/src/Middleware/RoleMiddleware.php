<?php
declare(strict_types=1);

namespace Ayivonpome\Middleware;

use Ayivonpome\Utils\JsonResponse;

final class RoleMiddleware
{
    public static function requireRole(array $session, array $roles): void
    {
        if (!in_array($session['role'] ?? 'viewer', $roles, true)) {
            JsonResponse::error('FORBIDDEN', 'Permission insuffisante.', 403);
        }
    }
}

