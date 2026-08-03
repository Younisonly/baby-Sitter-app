<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Conversation extends Model
{
    use SoftDeletes;

    protected $table = 'conversations';

    protected $fillable = [
        'participant_one_id', 'participant_two_id', 'last_message_content',
        'last_message_type', 'last_message_at', 'last_sender_id', 'archived_at',
    ];

    protected function casts(): array
    {
        return [
            'last_message_at' => 'datetime',
            'archived_at' => 'datetime',
        ];
    }

    public function participantOne(): BelongsTo
    {
        return $this->belongsTo(User::class, 'participant_one_id');
    }

    public function participantTwo(): BelongsTo
    {
        return $this->belongsTo(User::class, 'participant_two_id');
    }

    public function lastSender(): BelongsTo
    {
        return $this->belongsTo(User::class, 'last_sender_id');
    }

    public function messages(): HasMany
    {
        return $this->hasMany(Message::class);
    }
}
