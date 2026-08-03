<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserNotificationSetting extends Model
{
    protected $table = 'user_notification_settings';

    protected $fillable = [
        'user_id', 'booking_enabled', 'chat_enabled', 'review_enabled',
        'followers_enabled', 'support_enabled', 'security_enabled',
        'promotion_enabled', 'push_enabled', 'in_app_enabled',
        'quiet_hours_start', 'quiet_hours_end',
    ];

    protected function casts(): array
    {
        return [
            'booking_enabled' => 'boolean',
            'chat_enabled' => 'boolean',
            'review_enabled' => 'boolean',
            'followers_enabled' => 'boolean',
            'support_enabled' => 'boolean',
            'security_enabled' => 'boolean',
            'promotion_enabled' => 'boolean',
            'push_enabled' => 'boolean',
            'in_app_enabled' => 'boolean',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
