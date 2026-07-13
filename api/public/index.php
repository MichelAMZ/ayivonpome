<?php
declare(strict_types=1);

use Ayivonpome\Config\Database;
use Ayivonpome\Config\Env;
use Ayivonpome\Controllers\AdminController;
use Ayivonpome\Controllers\AuthController;
use Ayivonpome\Controllers\BackupController;
use Ayivonpome\Controllers\BrandingController;
use Ayivonpome\Controllers\BugReportController;
use Ayivonpome\Controllers\CouncilController;
use Ayivonpome\Controllers\FamilyController;
use Ayivonpome\Controllers\FamilyHistoryController;
use Ayivonpome\Controllers\MarriageController;
use Ayivonpome\Controllers\NotificationController;
use Ayivonpome\Controllers\PersonController;
use Ayivonpome\Controllers\RelationshipController;
use Ayivonpome\Controllers\SyncController;
use Ayivonpome\Middleware\AuthMiddleware;
use Ayivonpome\Middleware\CorsMiddleware;
use Ayivonpome\Middleware\RateLimitMiddleware;
use Ayivonpome\Middleware\RoleMiddleware;
use Ayivonpome\Utils\JsonResponse;
use Ayivonpome\Utils\Request;

$autoload = dirname(__DIR__) . '/vendor/autoload.php';
if (is_file($autoload)) {
    require $autoload;
} else {
    spl_autoload_register(static function (string $class): void {
        $prefix = 'Ayivonpome\\';
        if (!str_starts_with($class, $prefix)) {
            return;
        }
        $relative = str_replace('\\', '/', substr($class, strlen($prefix)));
        $file = dirname(__DIR__) . '/src/' . $relative . '.php';
        if (is_file($file)) {
            require $file;
        }
    });
}

Env::load(dirname(__DIR__) . '/.env');
CorsMiddleware::handle();
RateLimitMiddleware::handle();

if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$request = new Request();
$method = $request->method();
$path = rtrim($request->path(), '/') ?: '/';

try {
    if ($method === 'GET' && $path === '/health') {
        Database::connection()->query('SELECT 1');
        JsonResponse::success(['api' => 'online', 'database' => 'connected']);
    }

    if ($method === 'POST' && $path === '/auth/access-code') {
        (new AuthController())->code($request, 'family_access');
    }
    if ($method === 'POST' && $path === '/auth/admin-code') {
        (new AuthController())->code($request, 'admin_kpi');
    }
    if ($method === 'POST' && $path === '/auth/modification-code') {
        (new AuthController())->code($request, 'modification');
    }
    if ($method === 'POST' && $path === '/auth/recovery-code') {
        (new AuthController())->code($request, 'super_admin_recovery');
    }

    $publicRead = $method === 'GET' && preg_match('#^/(families|people)(/[^/]+)?$#', $path);
    $session = $publicRead ? ['family_id' => $request->query('familyId'), 'role' => 'viewer'] : AuthMiddleware::requireSession($request);

    if ($method === 'GET' && $path === '/auth/session') {
        (new AuthController())->session($session);
    }
    if ($method === 'POST' && $path === '/auth/logout') {
        JsonResponse::success();
    }

    if ($method === 'GET' && $path === '/families') {
        (new FamilyController())->index();
    }
    if ($method === 'POST' && $path === '/families') {
        RoleMiddleware::requireRole($session, ['admin', 'super_admin']);
        (new FamilyController())->save($request);
    }
    if (preg_match('#^/families/([^/]+)$#', $path, $m)) {
        if ($method === 'GET') {
            (new FamilyController())->show($m[1]);
        }
        if ($method === 'PUT') {
            RoleMiddleware::requireRole($session, ['admin', 'super_admin']);
            (new FamilyController())->save($request);
        }
    }

    if ($method === 'GET' && $path === '/people') {
        (new PersonController())->index($request, $session);
    }
    if ($method === 'POST' && $path === '/people') {
        RoleMiddleware::requireRole($session, ['editor', 'admin', 'super_admin']);
        (new PersonController())->save($request, $session);
    }
    if (preg_match('#^/people/([^/]+)/linked-tree$#', $path, $m) && $method === 'GET') {
        (new PersonController())->linkedTree($m[1]);
    }
    if (preg_match('#^/people/([^/]+)$#', $path, $m)) {
        if ($method === 'GET') {
            (new PersonController())->show($m[1]);
        }
        if ($method === 'PUT') {
            RoleMiddleware::requireRole($session, ['editor', 'admin', 'super_admin']);
            (new PersonController())->save($request, $session);
        }
        if ($method === 'DELETE') {
            RoleMiddleware::requireRole($session, ['admin', 'super_admin']);
            (new PersonController())->delete($m[1], $session);
        }
    }

    if ($method === 'GET' && $path === '/relationships') {
        (new RelationshipController())->index($request, $session);
    }
    if ($method === 'GET' && $path === '/marriages') {
        (new MarriageController())->index($request, $session);
    }
    if ($method === 'GET' && $path === '/history/family') {
        (new FamilyHistoryController())->index();
    }
    if ($method === 'GET' && $path === '/council') {
        (new CouncilController())->index();
    }
    if ($method === 'GET' && $path === '/notifications') {
        (new NotificationController())->index();
    }
    if ($method === 'GET' && $path === '/bug-reports') {
        (new BugReportController())->index();
    }
    if ($method === 'GET' && $path === '/admin/kpi') {
        RoleMiddleware::requireRole($session, ['admin', 'super_admin']);
        (new AdminController())->kpi($session);
    }
    if ($path === '/admin/branding') {
        RoleMiddleware::requireRole($session, ['admin', 'super_admin']);
        if ($method === 'GET') {
            (new BrandingController())->show($session);
        }
        if ($method === 'PUT') {
            (new BrandingController())->update($request, $session);
        }
    }
    if ($path === '/admin/branding/logo') {
        RoleMiddleware::requireRole($session, ['admin', 'super_admin']);
        if ($method === 'POST') {
            (new BrandingController())->uploadLogo($session);
        }
        if ($method === 'DELETE') {
            (new BrandingController())->deleteLogo($session);
        }
    }
    if ($method === 'POST' && $path === '/admin/branding/logo/restore-default') {
        RoleMiddleware::requireRole($session, ['admin', 'super_admin']);
        (new BrandingController())->restoreDefault($session);
    }
    if ($method === 'POST' && $path === '/admin/branding/favicon') {
        RoleMiddleware::requireRole($session, ['admin', 'super_admin']);
        (new BrandingController())->favicon($request, $session);
    }

    if ($method === 'POST' && $path === '/sync/push') {
        (new SyncController())->push($request, $session);
    }
    if ($method === 'GET' && $path === '/sync/pull') {
        (new SyncController())->pull($request, $session);
    }
    if (preg_match('#^/export/family/([^/]+)$#', $path, $m) && $method === 'GET') {
        (new BackupController())->export($request, $m[1]);
    }
    if ($method === 'POST' && $path === '/backups') {
        RoleMiddleware::requireRole($session, ['admin', 'super_admin']);
        (new BackupController())->create($request, $session);
    }

    JsonResponse::error('NOT_FOUND', 'Route introuvable.', 404);
} catch (Throwable $error) {
    if (Env::bool('APP_DEBUG')) {
        JsonResponse::error('SERVER_ERROR', $error->getMessage(), 500);
    }
    JsonResponse::error('SERVER_ERROR', 'Erreur serveur.', 500);
}
