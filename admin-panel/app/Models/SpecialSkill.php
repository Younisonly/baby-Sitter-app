<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SpecialSkill extends Model
{
    protected $table = 'special_skills';

    protected $fillable = [
        'key', 'label', 'label_ar', 'icon', 'sort_order', 'is_active',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'sort_order' => 'integer',
        ];
    }
}
