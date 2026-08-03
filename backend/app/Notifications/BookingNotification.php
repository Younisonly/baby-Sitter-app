<?php

namespace App\Notifications;

use App\Channels\FcmPushChannel;
use App\Models\Booking;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class BookingNotification extends Notification
{
    use Queueable;

    public function __construct(
        private readonly string $titleKey,
        private readonly string $bodyKey,
        private readonly array $replacements,
        private readonly Booking $booking,
        private readonly string $status,
    ) {}

    public function via(object $notifiable): array
    {
        $cacheKey = "booking_notification_{$notifiable->id}_{$this->booking->id}_{$this->status}";
        // Global debounce: Prevent duplicate notifications for the same booking and status within 1 minute
        if (!\Illuminate\Support\Facades\Cache::add($cacheKey, true, now()->addMinutes(1))) {
            return [];
        }

        return ['app_database', FcmPushChannel::class];
    }

    public function toDatabase(object $notifiable): array
    {
        // IMPORTANT: store the RAW template key (e.g. "booking_in_progress_sitter_title")
        // and clean replacements so Flutter can resolve text in the user's active locale.
        // Pre-resolving here caused: wrong language, unresolved tokens if any value was
        // missing, and inability to re-localize when user changes language.
        $cleanReplacements = $this->cleanReplacements();

        return [
            // Flutter reads title_key / body_key to pick the right localization string.
            'title_key'      => $this->titleKey,
            'body_key'       => $this->bodyKey,
            // Also resolve for the DB title/body columns (used as fallback by old clients).
            'title'          => $this->resolveTitle(),
            'body'           => $this->resolveBody(),
            'type'           => 'booking_' . $this->status,
            'show_push'      => true,
            'show_in_app'    => true,
            'action_key'     => $this->resolveActionKey(),
            'deep_link_type' => 'booking',
            'deep_link_id'   => (string) $this->booking->id,
            // Flat replacement values at the top level so Flutter's
            // NotificationLocalizationService can interpolate without nested lookup.
            'data_json'      => array_merge($cleanReplacements, [
                'booking_id'  => (string) $this->booking->id,
                'status'      => $this->status,
                'action_url'  => '/bookings/' . $this->booking->id,
            ]),
        ];
    }

    public function toFcmPush(object $notifiable): array
    {
        $cleanReplacements = $this->cleanReplacements();
        // Do NOT prefix with user name — confusing and redundant.
        return [
            'title'           => $this->resolveTitle(),
            'body'            => $this->resolveBody(),
            'deep_link_type'  => 'booking',
            'deep_link_id'    => (string) $this->booking->id,
            'notification_id' => null,
            // Passed through to FCM data payload for foreground re-localization.
            'action_key'      => $this->resolveActionKey(),
            'replacements'    => $cleanReplacements,
        ];
    }

    private function resolveTitle(): string
    {
        $title = __("notifications.{$this->titleKey}");
        foreach ($this->replacements as $key => $value) {
            $title = str_replace($key, $value, $title);
        }
        return $title;
    }

    private function resolveBody(): string
    {
        $body = __("notifications.{$this->bodyKey}", $this->replacements);
        foreach ($this->replacements as $key => $value) {
            $body = str_replace($key, $value, $body);
        }
        return $body;
    }

    private function resolveActionKey(): string
    {
        return match ($this->status) {
            'pending' => 'booking_created',
            'confirmed' => 'booking_confirmed',
            'rejected' => 'booking_rejected',
            'cancelled' => 'booking_cancelled',
            'completed' => 'booking_completed',
            'rescheduled' => 'booking_rescheduled',
            'updated' => 'booking_updated',
            default => 'booking_' . $this->status,
        };
    }

    private function cleanReplacements(): array
    {
        $clean = [];
        foreach ($this->replacements as $key => $value) {
            $cleanKey = trim($key, '{}');
            $clean[$cleanKey] = $value;
        }
        return $clean;
    }
}
