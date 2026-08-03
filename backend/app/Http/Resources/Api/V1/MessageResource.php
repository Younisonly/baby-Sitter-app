<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class MessageResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'conversation_id' => $this->conversation_id,
            'sender_id' => $this->sender_id,
            'sender_name' => $this->sender?->name,
            'content' => $this->content,
            'type' => $this->type,
            'image_url' => $this->image_url
                ? (str_starts_with($this->image_url, 'http') ? $this->image_url : url($this->image_url))
                : null,
            'message_type' => $this->message_type ?? 'text',
            'metadata' => $this->metadata,
            'is_system' => (bool) $this->is_system,
            'is_edited' => $this->edited_at !== null,
            'reply_to' => $this->whenLoaded('replyTo', fn () => $this->replyTo ? [
                'id' => $this->replyTo->id,
                'conversation_id' => $this->replyTo->conversation_id,
                'content' => $this->replyTo->content,
                'sender_id' => $this->replyTo->sender_id,
                'sender_name' => $this->replyTo->sender?->name,
                'message_type' => $this->replyTo->message_type ?? 'text',
                'created_at' => $this->replyTo->created_at->toIso8601String(),
            ] : null),
            'reactions' => $this->whenLoaded('reactions', fn () => $this->reactions->map(fn ($r) => [
                'id' => $r->id,
                'message_id' => $r->message_id,
                'user_id' => $r->user_id,
                'reaction' => $r->reaction,
            ])->toArray()),
            'attachments' => $this->whenLoaded('attachments', fn () => $this->attachments->map(fn ($a) => [
                'id' => $a->id,
                'message_id' => $a->message_id,
                'file_path' => $a->file_path,
                'file_url' => $a->file_path ? url(Storage::url($a->file_path)) : null,
                'file_name' => $a->file_name,
                'file_size' => $a->file_size,
                'mime_type' => $a->mime_type,
                'file_type' => $a->file_type,
            ])->toArray()),
            'read_at' => $this->read_at?->toIso8601String(),
            'created_at' => $this->created_at->toIso8601String(),
            'updated_at' => $this->updated_at->toIso8601String(),
        ];
    }
}
