<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Message extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'conversation_id',
        'sender_id',
        'content',
        'type',
        'image_url',
        'reply_to_id',
        'message_type',
        'metadata',
        'is_system',
        'read_at',
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
        return $this->belongsTo(self::class, 'reply_to_id');
    }

    public function replies(): HasMany
    {
        return $this->hasMany(self::class, 'reply_to_id');
    }

    public function reactions(): HasMany
    {
        return $this->hasMany(MessageReaction::class);
    }

    public function attachments(): HasMany
    {
        return $this->hasMany(MessageAttachment::class);
    }
}
