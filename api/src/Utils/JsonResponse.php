<?php
declare(strict_types=1);

namespace Ayivonpome\Utils;

final class JsonResponse
{
    public static function success(mixed $data = null, string $message = '', int $status = 200): void
    {
        self::send([
            'success' => true,
            'data' => $data ?? new \stdClass(),
            'message' => $message,
            'serverTime' => gmdate('c'),
        ], $status);
    }

    public static function error(string $code, string $message, int $status = 400, array $fields = []): void
    {
        self::send([
            'success' => false,
            'error' => [
                'code' => $code,
                'message' => $message,
                'fields' => $fields,
            ],
            'serverTime' => gmdate('c'),
        ], $status);
    }

    private static function send(array $payload, int $status): void
    {
        http_response_code($status);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }
}

