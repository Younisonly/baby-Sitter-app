<?php

use App\Exceptions\BookingConflictException;
use App\Http\Middleware\CheckSuspended;
use App\Http\Middleware\ForceJsonMiddleware;
use App\Http\Middleware\RemoveServerHeadersMiddleware;
use App\Http\Middleware\SecurityHeadersMiddleware;
use App\Http\Middleware\SetLocaleFromHeader;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\HttpKernel\Exception\TooManyRequestsHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
        apiPrefix: 'api',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        // Run locale detection globally first — before FormRequest validation fires
        $middleware->prepend(SetLocaleFromHeader::class);

        $middleware->api(append: [
            \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
            ForceJsonMiddleware::class,
            SecurityHeadersMiddleware::class,
            RemoveServerHeadersMiddleware::class,
        ]);

        $middleware->alias([
            'suspended' => CheckSuspended::class,
            'admin' => \App\Http\Middleware\CheckAdminRole::class,
            'role.parent' => \App\Http\Middleware\CheckParentRole::class,
            'role.sitter' => \App\Http\Middleware\CheckSitterRole::class,
        ]);
        $middleware->redirectGuestsTo(function (Request $request) {
            if ($request->is('api/*') || $request->expectsJson()) {
                return null;
            }
            return route('login');
        });
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->render(function (Throwable $e, Request $request) {
            if (! $request->is('api/*') && ! $request->expectsJson()) {
                return null;
            }

            $status = match (true) {
                $e instanceof TooManyRequestsHttpException => 429,
                $e instanceof NotFoundHttpException,
                $e instanceof ModelNotFoundException => 404,
                $e instanceof AuthenticationException => 401,
                $e instanceof AuthorizationException => 403,
                $e instanceof BookingConflictException => 409,
                $e instanceof HttpException => $e->getStatusCode(),
                default => 500,
            };

            $message = match (true) {
                $e instanceof ValidationException => null,
                $e instanceof BookingConflictException => $e->getMessage(),
                $status === 429 => __('messages.too_many_requests'),
                $status === 404 => __('messages.resource_not_found'),
                $status === 401 => __('messages.unauthenticated'),
                $status === 403 => __('messages.unauthorized_action'),
                default => __('messages.server_error'),
            };

            $errors = $e instanceof ValidationException ? $e->errors() : null;

            if ($errors) {
                $firstError = collect($errors)->flatten()->first();
                $message = $firstError ?? __('messages.check_input');
            }

            $response = [
                'status' => 'error',
                'message' => $message,
            ];

            if ($errors) {
                $response['errors'] = $errors;
            }

            return response()->json($response, $status);
        });
    })->create();
