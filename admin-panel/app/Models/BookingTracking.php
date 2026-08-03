<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BookingTracking extends Model
{
    protected $table = 'booking_tracking';

    public $timestamps = false;

    protected $fillable = [
        'booking_id', 'latitude', 'longitude', 'address', 'speed',
        'battery', 'recorded_at',
    ];

    protected function casts(): array
    {
        return [
            'latitude' => 'decimal:7',
            'longitude' => 'decimal:7',
            'speed' => 'decimal:2',
            'battery' => 'integer',
            'recorded_at' => 'datetime',
        ];
    }

    public function booking(): BelongsTo
    {
        return $this->belongsTo(Booking::class);
    }
}
