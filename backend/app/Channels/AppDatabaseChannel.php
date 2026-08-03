<?php

namespace App\Channels;

use App\Models\Notification;
use Illuminate\Notifications\Notification as IlluminateNotification;

final class AppDatabaseChannel
{
    public function send(object $notifiable, IlluminateNotification $notification): ?Notification
    {
        $data = $notification->toDatabase($notifiable);

        // The notification's data_json should already be a flat map of clean replacement
        // values (e.g. ['sitter_name' => 'Sara', 'date' => 'Jul 28', ...]).
        // We merge in title_key / body_key so Flutter knows the exact localization
        // key to look up, regardless of the action_key stored in the column.
        $dataJson = $data['data_json'] ?? [];
        if (isset($data['title_key'])) {
            $dataJson['title_key'] = $data['title_key'];
        }
        if (isset($data['body_key'])) {
            $dataJson['body_key'] = $data['body_key'];
        }
        if (isset($data['action_key'])) {
            $dataJson['action_key'] = $data['action_key'];
        }

        // Store the raw template strings (with {tokens}) as title/body so Flutter can
        // interpolate them if no localization key is found. Falls back to resolved text.
        $title = $data['title_key'] ?? ($data['title'] ?? '');
        $body  = $data['body_key']  ?? ($data['body']  ?? '');

        return Notification::create([
            'user_id'        => $notifiable->getKey(),
            'title'          => $title,
            'body'           => $body,
            'type'           => $data['type'] ?? 'system',
            'action_key'     => $data['action_key'] ?? $data['type'] ?? null,
            'is_read'        => false,
            'priority'       => 'normal',
            'language'       => $notifiable->preferred_language ?? 'en',
            'data_json'      => $dataJson,
            'deep_link_type' => $data['deep_link_type'] ?? null,
            'deep_link_id'   => $data['deep_link_id'] ?? null,
            'show_push'      => true,
            'show_in_app'    => true,
        ]);
    }
}
