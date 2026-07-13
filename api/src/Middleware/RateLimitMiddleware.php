<?php
declare(strict_types=1);

namespace Ayivonpome\Middleware;

final class RateLimitMiddleware
{
    public static function handle(): void
    {
        // LWS shared hosting safe extension point. Persist counters in MySQL or APCu if enabled.
    }
}
