<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BabysitterProfile extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'hourly_rate',
        'rating',
        'review_count',
        'years_experience',
        'description',
        'categories',
        'certificates',
        'gallery_images',
        'completed_bookings',
        'cancelled_bookings',
        'total_earnings',
        'view_count',
        'follower_count',
        'total_rejected',
        'is_available',
        'availability',
        'bank_account',
        'cancellation_policy_id',
        'included_children',
        'extra_child_fee',
        'absolute_max_children',
        'special_needs_rate',
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
            'included_children' => 'integer',
            'extra_child_fee' => 'decimal:2',
            'absolute_max_children' => 'integer',
            'special_needs_rate' => 'decimal:2',
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

    public function getBankAccountAttribute(?string $value): mixed
    {
        if ($value === null) {
            return null;
        }

        try {
            $decrypted = decrypt($value);
        } catch (\Exception $e) {
            return is_string($value) ? json_decode($value, true) : $value;
        }

        $decoded = json_decode($decrypted, true);

        return $decoded !== false ? $decoded : $decrypted;
    }
}
