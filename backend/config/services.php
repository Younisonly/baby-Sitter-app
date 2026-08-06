<?php

return [
    'fcm' => [
        'server_key' => env('FCM_SERVER_KEY', ''),
    ],

    'firebase' => [
        'project_id' => env('FIREBASE_PROJECT_ID', 'babysitter-29120'),
    ],

    'sms' => [
        // log | twilio | unifonic | 4jawaly | whatsapp
        'driver' => env('SERVICES_SMS_DRIVER', 'log'),

        // Twilio
        'twilio_sid' => env('TWILIO_SID', ''),
        'twilio_token' => env('TWILIO_AUTH_TOKEN', ''),
        'twilio_from' => env('TWILIO_FROM', ''),

        // Unifonic (Jordan / KSA)
        'unifonic_app_sid' => env('UNIFONIC_APP_SID', ''),
        'unifonic_sender_id' => env('UNIFONIC_SENDER_ID', ''),

        // 4jawaly (Saudi gateway)
        'jawaly_api_key' => env('JAWALY_API_KEY', ''),
    ],
];
