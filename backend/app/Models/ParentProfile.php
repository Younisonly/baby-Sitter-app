<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ParentProfile extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'preferences',
        'children_info',
        'emergency_contacts',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'preferences' => 'array',
            'children_info' => 'array',
            'emergency_contacts' => 'array',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
