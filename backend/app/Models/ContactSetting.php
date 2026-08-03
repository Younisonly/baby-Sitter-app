<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ContactSetting extends Model
{
    protected $fillable = [
        'email',
        'phone',
        'whatsapp',
        'facebook',
        'instagram',
        'x',
        'website',
    ];
}
