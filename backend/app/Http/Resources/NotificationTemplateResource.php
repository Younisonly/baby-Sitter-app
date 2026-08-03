<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class NotificationTemplateResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'actionKey' => $this->action_key,
            'titleEn' => $this->title_en,
            'titleAr' => $this->title_ar,
            'bodyEn' => $this->body_en,
            'bodyAr' => $this->body_ar,
            'category' => $this->category,
            'priority' => $this->priority,
            'allowPush' => $this->allow_push,
            'allowInApp' => $this->allow_in_app,
            'allowEmail' => $this->allow_email,
            'allowSms' => $this->allow_sms,
            'icon' => $this->icon,
            'deepLinkType' => $this->deep_link_type,
            'createdAt' => $this->created_at?->toJSON(),
            'updatedAt' => $this->updated_at?->toJSON(),
        ];
    }
}
