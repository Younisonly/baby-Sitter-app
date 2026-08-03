<?php

namespace App\Channels;

use App\Jobs\SendPushNotificationJob;
use App\Models\UserDevice;
use Illuminate\Notifications\Notification;

class FcmPushChannel
{
    public function send(object $notifiable, Notification $notification): void
    {
        $data = $notification->toFcmPush($notifiable);
        if (empty($data)) return;

        $devices = UserDevice::active()->where('user_id', $notifiable->id)->get();
        foreach ($devices as $device) {
            SendPushNotificationJob::dispatch(
                $device,
                $data['title'],
                $data['body'],
                $data['deep_link_type'] ?? null,
                $data['deep_link_id'] ?? null,
                $data['notification_id'] ?? null,
                $data['action_key'] ?? null,
                $data['replacements'] ?? [],
            );
        }
    }
}
