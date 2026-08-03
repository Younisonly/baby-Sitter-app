<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BabysitterProfile extends Model
{
    protected $table = 'babysitter_profiles';

    protected $fillable = [
        'user_id', 'hourly_rate', 'included_children', 'extra_child_fee',
        'absolute_max_children', 'special_needs_rate', 'rating', 'review_count',
        'years_experience', 'description', 'categories', 'certificates',
        'gallery_images', 'completed_bookings', 'cancelled_bookings',
        'total_earnings', 'view_count', 'follower_count', 'total_rejected',
        'is_available', 'offers_emergency', 'offers_overnight', 'availability',
        'cancellation_policy_id', 'bank_account',
    ];

    protected function casts(): array
    {
        return [
            'hourly_rate' => 'decimal:2',
            'rating' => 'decimal:2',
            'categories' => 'array',
            'certificates' => 'array',
            'gallery_images' => 'array',
            'availability' => 'array',
            'is_available' => 'boolean',
            'extra_child_fee' => 'decimal:2',
            'special_needs_rate' => 'decimal:2',
            'included_children' => 'integer',
            'absolute_max_children' => 'integer',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function cancellationPolicy(): BelongsTo
    {
        return $this->belongsTo(CancellationPolicy::class);
    }

    public function bookings(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(Booking::class, 'sitter_id', 'user_id');
    }
}
