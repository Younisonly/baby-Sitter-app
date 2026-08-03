<?php

return [
    'stateful' => explode(',', env('SANCTUM_STATEFUL_DOMAINS', 'localhost,127.0.0.1,10.0.2.2')),
    'guard' => ['web'],
    'expiration' => 60 * 24 * 30,
    'token_prefix' => env('SANCTUM_TOKEN_PREFIX', 'babysitter_'),
    'middleware' => [
        'authenticate_session' => Laravel\Sanctum\Http\Middleware\AuthenticateSession::class,
        'encrypt_cookies' => Illuminate\Cookie\Middleware\EncryptCookies::class,
        'validate_csrf_token' => Illuminate\Foundation\Http\Middleware\ValidateCsrfToken::class,
    ],
];
