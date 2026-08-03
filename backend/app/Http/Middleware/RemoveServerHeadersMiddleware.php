<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

final class RemoveServerHeadersMiddleware
{
    private const REMOVED_HEADERS = [
        'X-Powered-By',
        'Server',
    ];

    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        foreach (self::REMOVED_HEADERS as $header) {
            $response->headers->remove($header);
        }

        return $response;
    }
}
