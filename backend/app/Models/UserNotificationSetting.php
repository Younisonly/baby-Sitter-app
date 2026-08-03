<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserNotificationSetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'booking_enabled',
        'chat_enabled',
        'review_enabled',
        'followers_enabled',
        'support_enabled',
        'security_enabled',
        'promotion_enabled',
        'push_enabled',
        'in_app_enabled',
        'quiet_hours_start',
        'quiet_hours_end',
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

    public function isCategoryEnabled(string $category): bool
    {
        return match ($category) {
            'booking' => (bool) ($this->booking_enabled ?? false),
            'chat' => (bool) ($this->chat_enabled ?? false),
            'review' => (bool) ($this->review_enabled ?? false),
            'followers' => (bool) ($this->followers_enabled ?? false),
            'support' => (bool) ($this->support_enabled ?? false),
            'security' => (bool) ($this->security_enabled ?? false),
            'promotion' => (bool) ($this->promotion_enabled ?? false),
            default => true,
        };
    }

    public function isInQuietHours(): bool
    {
        if (!$this->quiet_hours_start || !$this->quiet_hours_end) {
            return false;
        }

        $now = now();
        $start = \Carbon\Carbon::createFromFormat('H:i', $this->quiet_hours_start);
        $end = \Carbon\Carbon::createFromFormat('H:i', $this->quiet_hours_end);

        if ($start <= $end) {
            return $now->between($start, $end);
        }

        return $now->gte($start) || $now->lte($end);
    }
}
