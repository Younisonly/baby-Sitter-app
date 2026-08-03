<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\TimelineEvent;

final class TimelineService
{
    public function recordStatusChange(
        Booking $booking,
        string $fromStatus,
        string $toStatus,
        ?int $actorId = null,
        ?string $reason = null,
    ): TimelineEvent {
        return TimelineEvent::create([
            'booking_id' => $booking->id,
            'type' => 'status_change',
            'payload' => [
                'from' => $fromStatus,
                'to' => $toStatus,
                'reason' => $reason,
                'old_total' => (float) $booking->total_amount,
            ],
            'actor_id' => $actorId,
        ]);
    }

    public function recordCreation(Booking $booking): TimelineEvent
    {
        return TimelineEvent::create([
            'booking_id' => $booking->id,
            'type' => 'created',
            'payload' => [
                'date' => $booking->date->toDateString(),
                'start_time' => $booking->start_time,
                'end_time' => $booking->end_time,
                'total_amount' => (float) $booking->total_amount,
                'children_count' => $booking->children_count,
            ],
            'actor_id' => $booking->customer_id,
        ]);
    }

    public function recordReview(Booking $booking): TimelineEvent
    {
        return TimelineEvent::create([
            'booking_id' => $booking->id,
            'type' => 'reviewed',
            'payload' => [
                'rating' => $booking->rating,
            ],
            'actor_id' => $booking->customer_id,
        ]);
    }

    public function recordRebook(Booking $oldBooking, Booking $newBooking): TimelineEvent
    {
        TimelineEvent::create([
            'booking_id' => $oldBooking->id,
            'type' => 'rebooked',
            'payload' => [
                'new_booking_id' => $newBooking->id,
            ],
        ]);

        return TimelineEvent::create([
            'booking_id' => $newBooking->id,
            'type' => 'rebook_from',
            'payload' => [
                'original_booking_id' => $oldBooking->id,
            ],
        ]);
    }

    public function recordAdminAction(Booking $booking, string $action, ?int $actorId = null, ?string $reason = null): TimelineEvent
    {
        return TimelineEvent::create([
            'booking_id' => $booking->id,
            'type' => 'admin_override',
            'payload' => [
                'action' => $action,
                'reason' => $reason,
                'previous_status' => $booking->status,
            ],
            'actor_id' => $actorId,
        ]);
    }
}
