<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class SetLocaleFromHeader
{
    public function handle(Request $request, Closure $next): Response
    {
        $locale = $request->header('Accept-Language', 'en');

        // Normalize: take only the first tag, e.g. "ar-SA" → "ar"
        $locale = strtolower(trim(explode(',', $locale)[0]));
        $locale = explode('-', $locale)[0];

        // Only allow our supported locales
        if (!in_array($locale, ['en', 'ar'])) {
            $locale = 'en';
        }

        app()->setLocale($locale);

        return $next($request);
    }
}
