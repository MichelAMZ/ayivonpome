<?php
declare(strict_types=1);

namespace Ayivonpome\Controllers;

use Ayivonpome\Utils\JsonResponse;

final class CouncilController
{
    public function index(): void
    {
        JsonResponse::success([]);
    }
}

