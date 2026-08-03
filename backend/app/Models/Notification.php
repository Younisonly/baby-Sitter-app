<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Notification extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'template_id',
        'title',
        'body',
        'type',
        'action_key',
        'language',
        'data_json',
        'is_read',
        'read_at',
        'priority',
        'icon',
        'image',
        'deep_link_type',
        'deep_link_id',
        'show_push',
        'show_in_app',
    ];

    protected function casts(): array
    {
        return [
            'is_read' => 'boolean',
            'read_at' => 'datetime',
            'data_json' => 'array',
            'show_push' => 'boolean',
            'show_in_app' => 'boolean',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function template(): BelongsTo
    {
        return $this->belongsTo(NotificationTemplate::class, 'template_id');
    }

    public function scopeUnread($query)
    {
        return $query->where('is_read', false);
    }

    public function scopeByCategory($query, string $category)
    {
        return $query->whereHas('template', fn($q) => $q->where('category', $category));
    }

    public function scopeByActionKey($query, string $actionKey)
    {
        return $query->where('action_key', $actionKey);
    }

    public function markAsRead(): void
    {
        $this->update(['is_read' => true, 'read_at' => now()]);
    }
}
