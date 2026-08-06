<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckSitterRole
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (! $user || ! $user->canActAsSitter()) {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.need_sitter_profile'),
            ], 403);
        }

        return $next($request);
    }
}
