<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckSuspended
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user && $user->is_suspended) {
            return response()->json([
                'status' => 'error',
                'message' => 'Your account has been suspended. Please contact support for more information.',
            ], 403);
        }

        return $next($request);
    }
}
