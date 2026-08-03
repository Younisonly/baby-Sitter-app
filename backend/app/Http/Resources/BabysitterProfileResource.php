<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BabysitterProfileResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'userId' => (string) $this->user_id,
            'hourlyRate' => (float) $this->hourly_rate,
            'rating' => (float) $this->rating,
            'reviewCount' => (int) $this->review_count,
            'yearsExperience' => (int) $this->years_experience,
            'description' => $this->description,
            'categories' => $this->categories ?? [],
            'certificates' => $this->certificates ?? [],
            'galleryImages' => $this->gallery_images ?? [],
            'completedBookings' => (int) $this->completed_bookings,
            'cancelledBookings' => (int) $this->cancelled_bookings,
            'totalEarnings' => (int) $this->total_earnings,
            'isAvailable' => (bool) $this->is_available,
            'availability' => collect($this->availability ?? [])->map(fn (array $slot): array => [
                'dayOfWeek' => (int) ($slot['dayOfWeek'] ?? $slot['day_of_week'] ?? 1),
                'startTime' => (string) ($slot['startTime'] ?? $slot['start_time'] ?? '09:00'),
                'endTime' => (string) ($slot['endTime'] ?? $slot['end_time'] ?? '17:00'),
            ])->values(),
            'bankAccount' => $this->when($request->user()?->id === $this->user_id, $this->bank_account),
            'includedChildren' => (int) ($this->included_children ?? 1),
            'extraChildFee' => (float) ($this->extra_child_fee ?? 0),
            'absoluteMaxChildren' => $this->absolute_max_children ? (int) $this->absolute_max_children : null,
            'specialNeedsRate' => (float) $this->special_needs_rate,
            'followerCount' => (int) ($this->follower_count ?? 0),
        ];
    }
}
