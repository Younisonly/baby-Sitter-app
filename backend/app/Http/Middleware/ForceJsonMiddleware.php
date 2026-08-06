<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

final class ForceJsonMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        if (! $request->expectsJson() && ! $request->is('sanctum/csrf-cookie')) {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.only_json_requests_accepted'),
            ], 406);
        }

        return $next($request);
    }
}
