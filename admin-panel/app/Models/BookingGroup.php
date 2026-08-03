<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class BookingGroup extends Model
{
    protected $fillable = [
        'id',
        'customer_id',
        'sitter_id',
        'total_amount',
        'base_amount',
        'extra_amount',
        'special_needs_amount',
        'session_count',
        'completed_count',
        'cancelled_count',
        'first_date',
        'last_date',
        'status',
        'rating',
        'review',
    ];

    protected function casts(): array
    {
        return [
            'id' => 'string',
            'total_amount' => 'decimal:2',
            'base_amount' => 'decimal:2',
            'extra_amount' => 'decimal:2',
            'special_needs_amount' => 'decimal:2',
            'session_count' => 'integer',
            'completed_count' => 'integer',
            'cancelled_count' => 'integer',
            'first_date' => 'date',
            'last_date' => 'date',
            'rating' => 'decimal:2',
        ];
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function sitter(): BelongsTo
    {
        return $this->belongsTo(User::class, 'sitter_id');
    }

    public function bookings(): HasMany
    {
        return $this->hasMany(Booking::class, 'booking_group_id', 'id');
    }
}
