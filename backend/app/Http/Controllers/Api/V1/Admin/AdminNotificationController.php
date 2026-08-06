<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\NotificationResource;
use App\Http\Resources\NotificationTemplateResource;
use App\Models\Notification;
use App\Models\NotificationAuditLog;
use App\Models\NotificationTemplate;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class AdminNotificationController extends Controller
{
    public function templates(): AnonymousResourceCollection
    {
        return NotificationTemplateResource::collection(NotificationTemplate::all());
    }

    public function updateTemplate(Request $request, NotificationTemplate $template): JsonResponse
    {
        $validated = $request->validate([
            'title_en' => 'string|max:255',
            'title_ar' => 'string|max:255',
            'body_en' => 'string',
            'body_ar' => 'string',
            'category' => 'string|max:50',
            'priority' => 'string|in:low,normal,high,critical',
            'icon' => 'nullable|string|max:100|exists:app_icons,key',
            'allow_push' => 'boolean',
            'allow_in_app' => 'boolean',
            'allow_email' => 'boolean',
            'allow_sms' => 'boolean',
        ]);

        $template->update($validated);

        $template->refresh();

        return response()->json([
            'status' => 'success',
            'message' => __('messages.template_updated'),
            'data' => NotificationTemplateResource::make($template),
        ]);
    }

    public function previewTemplate(Request $request, NotificationTemplate $template): JsonResponse
    {
        $replacements = $request->input('replacements', []);
        $locale = $request->input('locale', 'en');

        return response()->json([
            'status' => 'success',
            'data' => [
                'title' => $template->resolveTitle($locale, $replacements),
                'body' => $template->resolveBody($locale, $replacements),
                'title_en' => $template->title_en,
                'title_ar' => $template->title_ar,
                'body_en' => $template->body_en,
                'body_ar' => $template->body_ar,
            ],
        ]);
    }

    public function allNotifications(Request $request): AnonymousResourceCollection
    {
        $query = Notification::query();

        if ($request->input('user_id')) {
            $query->where('user_id', $request->input('user_id'));
        }

        if ($request->input('action_key')) {
            $query->where('action_key', $request->input('action_key'));
        }

        if ($request->input('type')) {
            $query->where('type', $request->input('type'));
        }

        return NotificationResource::collection(
            $query->latest()->paginate($request->integer('per_page', 50)),
        );
    }

    public function auditLogs(Request $request): AnonymousResourceCollection|JsonResponse
    {
        $query = NotificationAuditLog::query();

        if ($request->input('channel')) {
            $query->where('channel', $request->input('channel'));
        }

        if ($request->input('status')) {
            $query->where('status', $request->input('status'));
        }

        $logs = $query->latest()->paginate($request->integer('per_page', 50));

        return response()->json([
            'status' => 'success',
            'data' => $logs->items(),
            'meta' => [
                'current_page' => $logs->currentPage(),
                'last_page' => $logs->lastPage(),
                'per_page' => $logs->perPage(),
                'total' => $logs->total(),
            ],
        ]);
    }

    public function stats(): JsonResponse
    {
        $totalSent = Notification::count();
        $totalRead = Notification::where('is_read', true)->count();
        $totalPushSent = NotificationAuditLog::where('channel', 'push')->where('status', 'sent')->count();
        $totalPushFailed = NotificationAuditLog::where('channel', 'push')->where('status', 'failed')->count();

        $readRate = $totalSent > 0 ? round(($totalRead / $totalSent) * 100, 2) : 0;
        $deliveryRate = ($totalPushSent + $totalPushFailed) > 0
            ? round(($totalPushSent / ($totalPushSent + $totalPushFailed)) * 100, 2)
            : 0;

        return response()->json([
            'status' => 'success',
            'data' => [
                'total_sent' => $totalSent,
                'total_read' => $totalRead,
                'read_rate' => $readRate,
                'push_sent' => $totalPushSent,
                'push_failed' => $totalPushFailed,
                'delivery_rate' => $deliveryRate,
            ],
        ]);
    }
}
