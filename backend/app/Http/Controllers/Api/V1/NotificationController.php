<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\NotificationResource;
use App\Models\Notification;
use App\Services\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class NotificationController extends Controller
{
    public function __construct(
        private readonly NotificationService $notificationService,
    ) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        $query = Notification::query()
            ->where('user_id', $request->user()->id)
            ->where('show_in_app', true);

        $filter = $request->input('filter');
        if ($filter && $filter !== 'all') {
            switch ($filter) {
                case 'unread':
                    $query->where('is_read', false);
                    break;
                default:
                    $query->where(function ($q) use ($filter) {
                        $q->whereHas('template', fn($t) => $t->where('category', $filter))
                          ->orWhere('action_key', 'like', "{$filter}_%")
                          ->orWhere('type', $filter);
                    });
                    break;
            }
        }

        $search = $request->input('search');
        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('body', 'like', "%{$search}%");
            });
        }

        $notifications = $query->latest()->paginate($request->integer('per_page', 20));

        return NotificationResource::collection($notifications);
    }

    public function unreadCount(Request $request): JsonResponse
    {
        $count = $this->notificationService->getUnreadCount($request->user());

        return response()->json([
            'status' => 'success',
            'data' => ['count' => $count],
        ]);
    }

    public function markAsRead(Request $request, Notification $notification): JsonResponse
    {
        $success = $this->notificationService->markAsRead($notification, $request->user());

        if (!$success) {
            return response()->json([
                'status' => 'error',
                'message' => 'Notification not found.',
            ], 404);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Notification marked as read.',
            'data' => NotificationResource::make($notification->fresh()),
        ]);
    }

    public function markAllAsRead(Request $request): JsonResponse
    {
        $count = $this->notificationService->markAllAsRead($request->user());

        return response()->json([
            'status' => 'success',
            'message' => "{$count} notifications marked as read.",
            'data' => ['count' => $count],
        ]);
    }

    public function markMultipleAsRead(Request $request): JsonResponse
    {
        $request->validate(['ids' => 'required|array', 'ids.*' => 'integer|exists:notifications,id']);

        $count = $this->notificationService->markMultipleAsRead($request->input('ids', []), $request->user());

        return response()->json([
            'status' => 'success',
            'message' => "{$count} notifications marked as read.",
            'data' => ['count' => $count],
        ]);
    }

    public function destroy(Request $request, Notification $notification): JsonResponse
    {
        $success = $this->notificationService->deleteNotification($notification, $request->user());

        if (!$success) {
            return response()->json([
                'status' => 'error',
                'message' => 'Notification not found.',
            ], 404);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Notification deleted.',
        ]);
    }

    public function destroyMultiple(Request $request): JsonResponse
    {
        $request->validate(['ids' => 'required|array', 'ids.*' => 'integer|exists:notifications,id']);

        $count = $this->notificationService->deleteMultiple($request->input('ids', []), $request->user());

        return response()->json([
            'status' => 'success',
            'message' => "{$count} notifications deleted.",
            'data' => ['count' => $count],
        ]);
    }
}
