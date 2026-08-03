<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TimelineEvent extends Model
{
    protected $fillable = [
        'booking_id',
        'type',
        'payload',
        'actor_id',
    ];

    protected function casts(): array
    {
        return [
            'payload' => 'array',
        ];
    }

    public function booking(): BelongsTo
    {
        return $this->belongsTo(Booking::class);
    }

    public function actor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'actor_id');
    }
}
