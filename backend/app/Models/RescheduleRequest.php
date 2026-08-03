<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RescheduleRequest extends Model
{
    use HasFactory;

    protected $fillable = [
        'booking_id',
        'requested_by_id',
        'status',
        'proposed_date',
        'proposed_start_time',
        'proposed_end_time',
        'reason',
        'counter_date',
        'counter_start_time',
        'counter_end_time',
        'counter_reason',
        'responded_at',
    ];

    protected function casts(): array
    {
        return [
            'proposed_date' => 'date',
            'counter_date' => 'date',
            'responded_at' => 'datetime',
        ];
    }

    public function booking(): BelongsTo
    {
        return $this->belongsTo(Booking::class);
    }

    public function requester(): BelongsTo
    {
        return $this->belongsTo(User::class, 'requested_by_id');
    }

    public function isPending(): bool
    {
        return $this->status === 'pending';
    }

    public function isOpen(): bool
    {
        return in_array($this->status, ['pending', 'countered'], true);
    }
}
