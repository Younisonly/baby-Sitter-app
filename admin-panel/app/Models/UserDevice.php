<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserDevice extends Model
{
    protected $table = 'user_devices';

    protected $fillable = [
        'user_id', 'device_token', 'platform', 'app_version', 'os_version',
        'device_name', 'is_active', 'last_active_at',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'last_active_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
