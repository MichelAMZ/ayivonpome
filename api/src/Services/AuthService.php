<?php
declare(strict_types=1);

namespace Ayivonpome\Services;

use Ayivonpome\Repositories\AdminRepository;

final class AuthService
{
    public function authenticate(string $type, string $code): ?array
    {
        $row = (new AdminRepository())->findValidCode($type, $code);
        return $row ? (new AdminRepository())->createSession($row) : null;
    }
}

