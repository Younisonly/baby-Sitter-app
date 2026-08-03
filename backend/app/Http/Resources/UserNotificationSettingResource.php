<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserNotificationSettingResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'bookingEnabled' => $this->booking_enabled,
            'chatEnabled' => $this->chat_enabled,
            'reviewEnabled' => $this->review_enabled,
            'followersEnabled' => $this->followers_enabled,
            'supportEnabled' => $this->support_enabled,
            'securityEnabled' => $this->security_enabled,
            'promotionEnabled' => $this->promotion_enabled,
            'pushEnabled' => $this->push_enabled,
            'inAppEnabled' => $this->in_app_enabled,
            'quietHoursStart' => $this->quiet_hours_start,
            'quietHoursEnd' => $this->quiet_hours_end,
        ];
    }
}
