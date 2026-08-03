<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Language extends Model
{
    protected $fillable = ['name', 'name_ar'];

    protected function casts(): array
    {
        return [
            'name' => 'string',
            'name_ar' => 'string',
        ];
    }
}
