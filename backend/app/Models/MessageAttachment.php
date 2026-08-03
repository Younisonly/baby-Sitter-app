<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MessageAttachment extends Model
{
    public const UPDATED_AT = null;

    protected $fillable = [
        'message_id',
        'file_path',
        'file_name',
        'file_size',
        'mime_type',
        'file_type',
    ];

    public function message(): BelongsTo
    {
        return $this->belongsTo(Message::class);
    }
}
