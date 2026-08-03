<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TimelineEventResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'type' => $this->type,
            'payload' => $this->payload,
            'actor' => $this->whenLoaded('actor', fn() => [
                'id' => (string) $this->actor->id,
                'name' => $this->actor->name,
            ]),
            'createdAt' => $this->created_at?->toJSON(),
        ];
    }
}
