<?php
declare(strict_types=1);

namespace Ayivonpome\Services;

final class CodeService
{
    public function hash(string $code): string
    {
        return password_hash($code, PASSWORD_DEFAULT);
    }

    public function verify(string $code, string $hash): bool
    {
        return password_verify($code, $hash);
    }
}

