<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Message extends Model
{
    use SoftDeletes;

    protected $table = 'messages';

    protected $fillable = [
        'conversation_id', 'sender_id', 'content', 'type', 'image_url',
        'reply_to_id', 'message_type', 'metadata', 'is_system', 'read_at',
    ];

    protected function casts(): array
    {
        return [
            'metadata' => 'array',
            'is_system' => 'boolean',
            'read_at' => 'datetime',
        ];
    }

    public function conversation(): BelongsTo
    {
        return $this->belongsTo(Conversation::class);
    }

    public function sender(): BelongsTo
    {
        return $this->belongsTo(User::class, 'sender_id');
    }

    public function replyTo(): BelongsTo
    {
        return $this->belongsTo(Message::class, 'reply_to_id');
    }
}
