<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserNotificationSettingResource;
use App\Models\UserNotificationSetting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationSettingController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $settings = UserNotificationSetting::firstOrCreate(
            ['user_id' => $request->user()->id],
        );

        return response()->json([
            'status' => 'success',
            'data' => UserNotificationSettingResource::make($settings),
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'booking_enabled' => 'boolean',
            'chat_enabled' => 'boolean',
            'review_enabled' => 'boolean',
            'followers_enabled' => 'boolean',
            'support_enabled' => 'boolean',
            'security_enabled' => 'boolean',
            'promotion_enabled' => 'boolean',
            'push_enabled' => 'boolean',
            'in_app_enabled' => 'boolean',
            'quiet_hours_start' => 'nullable|date_format:H:i',
            'quiet_hours_end' => 'nullable|date_format:H:i|required_with:quiet_hours_start',
        ]);

        $settings = UserNotificationSetting::updateOrCreate(
            ['user_id' => $request->user()->id],
            $validated,
        );

        return response()->json([
            'status' => 'success',
            'message' => 'Notification settings updated.',
            'data' => UserNotificationSettingResource::make($settings),
        ]);
    }
}
