<?php
declare(strict_types=1);

namespace Ayivonpome\Controllers;

use Ayivonpome\Utils\JsonResponse;

final class NotificationController
{
    public function index(): void
    {
        JsonResponse::success([]);
    }
}

