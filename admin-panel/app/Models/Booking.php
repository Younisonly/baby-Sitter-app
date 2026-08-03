<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Booking extends Model
{
    use HasFactory;

    protected $fillable = [
        'booking_number',
        'booking_group_id',
        'customer_id',
        'sitter_id',
        'date',
        'start_time',
        'end_time',
        'duration',
        'total_amount',
        'status',
        'session_status',
        'notes',
        'address',
        'children_count',
        'special_needs_count',
        'children_ages',
        'children_names',
        'special_instructions',
        'schedule_events',
        'cancellation_reason',
        'rejection_reason',
        'status_history',
        'confirmed_at',
        'in_progress_at',
        'completed_at',
        'cancelled_at',
        'rejected_at',
        'expired_at',
        'confirmation_deadline',
        'rescheduled_from_id',
        'rating',
        'review',
        'reply',
        'replied_at',
        'helpful_count',
        'reported_at',
        'base_amount',
        'extra_amount',
        'special_needs_amount',
        'qr_start_token',
        'qr_end_token',
        'session_started_at',
        'session_ended_at',
        'gps_started_at',
        'gps_ended_at',
        'overtime_minutes',
        'overtime_cost',
        'waiting_minutes',
        'waiting_cost',
        'expected_hours',
        'actual_hours',
        'session_notes',
        'is_day_completed',
        'day_completed_at',
    ];

    protected function casts(): array
    {
        return [
            'date' => 'date',
            'children_ages' => 'array',
            'children_names' => 'array',
            'schedule_events' => 'array',
            'status_history' => 'array',
            'confirmed_at' => 'datetime',
            'in_progress_at' => 'datetime',
            'completed_at' => 'datetime',
            'cancelled_at' => 'datetime',
            'rejected_at' => 'datetime',
            'expired_at' => 'datetime',
            'confirmation_deadline' => 'datetime',
            'replied_at' => 'datetime',
            'reported_at' => 'datetime',
            'total_amount' => 'decimal:2',
            'rating' => 'decimal:2',
            'session_started_at' => 'datetime',
            'session_ended_at' => 'datetime',
            'gps_started_at' => 'datetime',
            'gps_ended_at' => 'datetime',
            'expected_hours' => 'decimal:2',
            'actual_hours' => 'decimal:2',
            'is_day_completed' => 'boolean',
            'day_completed_at' => 'datetime',
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

    public function rescheduledFrom(): BelongsTo
    {
        return $this->belongsTo(Booking::class, 'rescheduled_from_id');
    }

    public function statusHistories(): HasMany
    {
        return $this->hasMany(BookingStatusHistory::class);
    }

    public function trackingLogs(): HasMany
    {
        return $this->hasMany(BookingTracking::class);
    }
}
