<?php
declare(strict_types=1);

namespace Ayivonpome\Services;

use Ayivonpome\Utils\Validator;

final class ValidationService
{
    public function person(array $payload): array
    {
        return Validator::requireFields($payload, ['familyId', 'firstName']);
    }
}

