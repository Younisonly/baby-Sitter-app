<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ConversationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $user = $request->user();
        $otherUser = $this->otherUser($user->id);

        return [
            'id' => $this->id,
            'other_user' => [
                'id' => $otherUser?->id,
                'name' => $otherUser?->name,
                'avatar' => $otherUser?->avatar,
                'role' => $otherUser?->role,
                'is_active_sitter' => $otherUser !== null,
                'last_seen_at' => $otherUser?->last_seen_at?->toIso8601String(),
            ],
            'last_message' => $this->last_message_content ? [
                'content' => $this->last_message_content,
                'sender_id' => $this->last_sender_id,
                'sender_name' => $this->lastSender?->name,
                'message_type' => $this->last_message_type ?? 'text',
                'created_at' => $this->last_message_at?->toIso8601String(),
            ] : null,
            'unread_count' => (int) ($this->unread_count ?? $this->unreadCount($user->id)),
            'is_archived' => $this->archived_at !== null,
            'archived_at' => $this->archived_at?->toIso8601String(),
            'created_at' => $this->created_at->toIso8601String(),
        ];
    }
}
