<?php
declare(strict_types=1);

namespace Ayivonpome\Middleware;

use Ayivonpome\Config\Env;

final class CorsMiddleware
{
    public static function handle(): void
    {
        $origin = $_SERVER['HTTP_ORIGIN'] ?? '';
        $allowed = array_filter(array_map('trim', explode(',', Env::get('FRONTEND_URL', ''))));
        if (Env::get('APP_ENV', 'production') !== 'production') {
            array_push($allowed, 'http://localhost:60760', 'http://localhost:8080', 'http://127.0.0.1:8080');
        }
        if ($origin !== '' && in_array($origin, $allowed, true)) {
            header('Access-Control-Allow-Origin: ' . $origin);
            header('Vary: Origin');
        }
        header('Access-Control-Allow-Credentials: true');
        header('Access-Control-Allow-Headers: Authorization, Content-Type, X-Requested-With');
        header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
        header('X-Content-Type-Options: nosniff');
        header('Referrer-Policy: no-referrer');
    }
}

