<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BookingStatusHistoryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'fromStatus' => $this->from_status,
            'toStatus' => $this->to_status,
            'reason' => $this->reason,
            'createdAt' => $this->created_at?->toJSON(),
            'changedBy' => $this->whenLoaded('changedBy', fn() => [
                'id' => (string) $this->changedBy->id,
                'name' => $this->changedBy->name,
            ]),
        ];
    }
}
