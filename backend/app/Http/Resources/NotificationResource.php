<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class NotificationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'userId' => (string) $this->user_id,
            'templateId' => $this->template_id ? (string) $this->template_id : null,
            'title' => $this->title,
            'body' => $this->body,
            'type' => $this->type,
            'actionKey' => $this->action_key,
            'language' => $this->language,
            'dataJson' => $this->data_json,
            'isRead' => $this->is_read,
            'readAt' => $this->read_at?->toJSON(),
            'priority' => $this->priority,
            'icon' => $this->icon,
            'image' => $this->image,
            'deepLinkType' => $this->deep_link_type,
            'deepLinkId' => $this->deep_link_id,
            'showPush' => $this->show_push,
            'showInApp' => $this->show_in_app,
            'createdAt' => $this->created_at?->toJSON(),
            'updatedAt' => $this->updated_at?->toJSON(),
        ];
    }
}
