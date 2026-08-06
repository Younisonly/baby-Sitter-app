<?php

namespace App\Http\Controllers\Api\V1;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;

class HeartbeatController extends Controller
{
    public function __invoke(Request $request): JsonResponse
    {
        $request->user()->forceFill(['last_seen_at' => now()])->saveQuietly();

        return response()->json([
            'status' => 'success',
            'message' => __('messages.ok'),
            'data' => [
                'last_seen_at' => now()->toIso8601String(),
            ],
        ]);
    }
}
