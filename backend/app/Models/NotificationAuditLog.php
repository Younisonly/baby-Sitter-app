<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class NotificationAuditLog extends Model
{
    use HasFactory;

    protected $fillable = [
        'notification_id',
        'user_id',
        'template_id',
        'action_key',
        'channel',
        'status',
        'error_message',
    ];
}
