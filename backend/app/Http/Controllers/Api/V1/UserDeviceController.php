<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\UserDevice;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UserDeviceController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'device_token' => 'required|string|max:500',
            'platform' => 'nullable|string|max:20',
            'app_version' => 'nullable|string|max:20',
            'os_version' => 'nullable|string|max:50',
            'device_name' => 'nullable|string|max:255',
        ]);

        $validated['user_id'] = $request->user()->id;
        $validated['last_active_at'] = now();

        UserDevice::where('user_id', $request->user()->id)
            ->where('device_token', $validated['device_token'])
            ->delete();

        $device = UserDevice::create($validated);

        return response()->json([
            'status' => 'success',
            'message' => 'Device registered.',
            'data' => ['id' => $device->id],
        ], 201);
    }

    public function destroy(Request $request): JsonResponse
    {
        $request->validate(['device_token' => 'required|string']);

        UserDevice::where('user_id', $request->user()->id)
            ->where('device_token', $request->input('device_token'))
            ->update(['is_active' => false]);

        return response()->json([
            'status' => 'success',
            'message' => 'Device unregistered.',
        ]);
    }
}
