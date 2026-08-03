<?php

namespace App\Services;

use App\Models\Notification;
use App\Models\NotificationTemplate;
use App\Models\User;
use App\Models\UserDevice;
use App\Models\NotificationAuditLog;
use App\Jobs\SendPushNotificationJob;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;

final class NotificationService
{
    private const CRITICAL_CATEGORIES = ['security', 'booking'];
    private const LOW_PRIORITY_CATEGORIES = ['followers', 'promotion'];

    public function __construct(
        private readonly FcmPushService $fcmPushService,
    ) {}

    public function send(
        User $user,
        string $actionKey,
        array $replacements = [],
        ?string $deepLinkId = null,
        ?string $image = null,
    ): ?Notification {
        // Global debounce: Prevent duplicate notifications for the same user, action, and reference within 1 minute
        $cacheKey = "notification_service_{$user->id}_{$actionKey}_{$deepLinkId}";
        if (!Cache::add($cacheKey, true, now()->addMinutes(1))) {
            return null; // Debounced
        }

        $template = NotificationTemplate::where('action_key', $actionKey)->first();

        if (!$template) {
            Log::warning("Notification template not found: {$actionKey}");
            return null;
        }

        $settings = $user->notificationSettings;

        if (!$settings) {
            $settings = $this->createDefaultSettings($user);
        }

        if (!$settings->isCategoryEnabled($template->category)) {
            return null;
        }

        $language = $user->preferred_language ?? 'en';

        // Store the raw (un-interpolated) template strings so the Flutter client
        // can resolve them at display time using its own locale-aware system.
        // This ensures correct localization even when the user changes language
        // after receiving the notification, and prevents broken text from missing
        // replacement values (old approach stripped unresolved {tokens}, producing
        // incomplete strings like "Your booking with on at").
        $rawTitle = $language === 'ar' ? $template->title_ar : $template->title_en;
        $rawBody  = $language === 'ar' ? $template->body_ar  : $template->body_en;

        // Also build a resolved version for the push notification display text.
        // For push we still resolve fully (best effort); any missing tokens produce
        // empty segments which is still better than raw tokens in the system tray.
        $resolvedTitle = $template->resolveTitle($language, $replacements);
        $resolvedBody  = $template->resolveBody($language, $replacements);

        $notification = null;

        DB::beginTransaction();
        try {
            if ($template->allow_in_app && $settings->in_app_enabled) {
                $notification = Notification::create([
                    'user_id'        => $user->id,
                    'template_id'    => $template->id,
                    // Store RAW template strings — Flutter resolves at display time.
                    'title'          => $rawTitle,
                    'body'           => $rawBody,
                    'action_key'     => $actionKey,
                    'type'           => $template->category,
                    'language'       => $language,
                    // data_json carries all replacement values so Flutter can interpolate.
                    'data_json'      => array_merge($replacements, [
                        'action_key'     => $actionKey,
                        'deep_link_type' => $template->deep_link_type,
                        'deep_link_id'   => $deepLinkId,
                    ]),
                    'priority'       => $template->priority,
                    'icon'           => $template->icon,
                    'image'          => $image,
                    'deep_link_type' => $template->deep_link_type,
                    'deep_link_id'   => $deepLinkId,
                    'show_push'      => $template->allow_push && $settings->push_enabled,
                    'show_in_app'    => true,
                ]);
            }

            $shouldPush = $template->allow_push
                && $settings->push_enabled
                && $this->shouldSendPush($template, $settings);

            if ($shouldPush) {
                // Pass resolved title/body for push display + raw replacements so
                // FCM data payload can include action_key and data_json for client-side
                // re-localization of foreground notifications.
                $this->dispatchPushNotification(
                    $user, $resolvedTitle, $resolvedBody,
                    $template, $deepLinkId, $notification, $replacements
                );
            }

            DB::commit();
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error("Failed to send notification: {$e->getMessage()}", [
                'user_id' => $user->id,
                'action_key' => $actionKey,
            ]);
            throw $e;
        }

        return $notification;
    }

    public function sendToMultipleUsers(
        array $userIds,
        string $actionKey,
        array $replacements = [],
        ?string $deepLinkId = null,
    ): void {
        $users = User::whereIn('id', $userIds)->get();

        foreach ($users as $user) {
            try {
                $this->send($user, $actionKey, $replacements, $deepLinkId);
            } catch (\Exception $e) {
                Log::error("Failed to notify user {$user->id}: {$e->getMessage()}");
                continue;
            }
        }
    }

    public function sendToSitterFollowers(
        User $sitter,
        string $actionKey,
        array $replacements = [],
    ): void {
        $followerIds = $sitter->followers()->pluck('users.id')->toArray();
        $this->sendToMultipleUsers($followerIds, $actionKey, $replacements, (string) $sitter->id);
    }

    public function markAsRead(Notification $notification, User $user): bool
    {
        if ($notification->user_id !== $user->id) {
            return false;
        }

        $notification->markAsRead();
        return true;
    }

    public function markAllAsRead(User $user): int
    {
        return Notification::where('user_id', $user->id)
            ->where('is_read', false)
            ->update(['is_read' => true, 'read_at' => now()]);
    }

    public function getUnreadCount(User $user): int
    {
        return Notification::where('user_id', $user->id)
            ->where('is_read', false)
            ->count();
    }

    public function deleteNotification(Notification $notification, User $user): bool
    {
        if ($notification->user_id !== $user->id) {
            return false;
        }

        $notification->delete();
        return true;
    }

    public function deleteMultiple(array $ids, User $user): int
    {
        return Notification::whereIn('id', $ids)
            ->where('user_id', $user->id)
            ->delete();
    }

    public function markMultipleAsRead(array $ids, User $user): int
    {
        return Notification::whereIn('id', $ids)
            ->where('user_id', $user->id)
            ->where('is_read', false)
            ->update(['is_read' => true, 'read_at' => now()]);
    }

    private function shouldSendPush(NotificationTemplate $template, $settings): bool
    {
        $category = $template->category;

        if (in_array($category, self::CRITICAL_CATEGORIES, true)) {
            return true;
        }

        if (in_array($category, self::LOW_PRIORITY_CATEGORIES, true) && $settings->isInQuietHours()) {
            return false;
        }

        return true;
    }

    private function dispatchPushNotification(
        User $user,
        string $title,
        string $body,
        NotificationTemplate $template,
        ?string $deepLinkId,
        ?Notification $notification,
        array $replacements = [],
    ): void {
        $devices = UserDevice::where('user_id', $user->id)->active()->get();

        if ($devices->isEmpty()) {
            return;
        }

        // Do NOT prefix with user name — the notification already contains the
        // user's name inside the body text (e.g. "Your booking with Ahmed...").
        foreach ($devices as $device) {
            SendPushNotificationJob::dispatch(
                $device,
                $title,
                $body,
                $template->deep_link_type,
                $deepLinkId,
                $notification?->id,
                $template->action_key,
                $replacements,
            );
        }
    }

    private function createDefaultSettings(User $user): \App\Models\UserNotificationSetting
    {
        return \App\Models\UserNotificationSetting::create([
            'user_id' => $user->id,
        ]);
    }

    public function logAudit(
        ?Notification $notification,
        ?User $user,
        ?NotificationTemplate $template,
        ?string $actionKey,
        string $channel,
        string $status,
        ?string $errorMessage = null,
    ): void {
        try {
            NotificationAuditLog::create([
                'notification_id' => $notification?->id,
                'user_id' => $user?->id ?? $notification?->user_id,
                'template_id' => $template?->id ?? $notification?->template_id,
                'action_key' => $actionKey ?? $notification?->action_key,
                'channel' => $channel,
                'status' => $status,
                'error_message' => $errorMessage,
            ]);
        } catch (\Exception $e) {
            Log::error("Failed to log notification audit: {$e->getMessage()}");
        }
    }
}
