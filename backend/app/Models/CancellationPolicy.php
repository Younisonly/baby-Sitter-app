<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class CancellationPolicy extends Model
{
    protected $fillable = [
        'name',
        'description',
        'refund_percent',
        'hours_before',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'refund_percent' => 'integer',
            'hours_before' => 'integer',
        ];
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function babysitterProfiles(): HasMany
    {
        return $this->hasMany(BabysitterProfile::class);
    }
}
