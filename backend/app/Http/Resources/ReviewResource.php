<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ReviewResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'bookingId' => (string) $this->id,
            'reviewerId' => (string) ($this->customer_id ?? ''),
            'reviewerName' => $this->whenLoaded('customer', fn () => $this->customer->name ?? 'Anonymous', 'Anonymous'),
            'reviewerAvatar' => $this->whenLoaded('customer', fn () => $this->customer->avatar, null),
            'rating' => (float) ($this->rating ?? 0),
            'comment' => $this->review,
            'subRatings' => null,
            'createdAt' => $this->updated_at?->toJSON(),
        ];
    }
}
