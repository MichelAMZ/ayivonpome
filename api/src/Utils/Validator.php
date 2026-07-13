<?php
declare(strict_types=1);

namespace Ayivonpome\Utils;

final class Validator
{
    public static function requireFields(array $payload, array $fields): array
    {
        $errors = [];
        foreach ($fields as $field) {
            if (!array_key_exists($field, $payload) || trim((string) $payload[$field]) === '') {
                $errors[$field] = 'required';
            }
        }
        return $errors;
    }

    public static function cleanString(mixed $value): string
    {
        return trim(strip_tags((string) $value));
    }
}

