<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class NotificationTemplate extends Model
{
    protected $table = 'notification_templates';

    protected $fillable = [
        'action_key', 'title_en', 'title_ar', 'body_en', 'body_ar',
        'category', 'priority', 'allow_push', 'allow_in_app', 'allow_email',
        'allow_sms', 'icon', 'deep_link_type',
    ];

    protected function casts(): array
    {
        return [
            'allow_push' => 'boolean',
            'allow_in_app' => 'boolean',
            'allow_email' => 'boolean',
            'allow_sms' => 'boolean',
        ];
    }

    public function notifications(): HasMany
    {
        return $this->hasMany(Notification::class);
    }
}
