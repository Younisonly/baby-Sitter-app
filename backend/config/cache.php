<?php

return [
    'default' => env('CACHE_STORE', 'database'),
    'stores' => [
        'database' => [
            'driver' => 'database',
            'table' => env('DB_CACHE_TABLE', 'cache'),
            'connection' => env('DB_CACHE_CONNECTION'),
            'lock_connection' => env('DB_CACHE_LOCK_CONNECTION'),
        ],
        'array' => [
            'driver' => 'array',
            'serialize' => false,
        ],
    ],
    'prefix' => env('CACHE_PREFIX', 'babysitter_cache_'),
];
