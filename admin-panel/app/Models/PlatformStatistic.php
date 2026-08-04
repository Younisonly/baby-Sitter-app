<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PlatformStatistic extends Model
{
    protected $table = 'platform_statistics';

    protected $fillable = [
        'key',
        'value',
        'label',
        'label_ar',
        'icon',
        'sort_order',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }
}
