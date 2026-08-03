<?php

namespace App\Services;

use App\Models\BabysitterProfile;
use App\Models\Booking;
use App\Models\BookingStatusHistory;
use App\Models\TimelineEvent;
use App\Models\User;
use App\Notifications\BookingNotification;
use Illuminate\Support\Facades\DB;

final class BookingService
{
    public function __construct(
        private readonly CancellationService $cancellationService,
        private readonly TimelineService $timelineService,
    ) {}

    public function calculateTotal(
        BabysitterProfile $profile,
        int $duration,
        int $childrenCount,
        int $specialNeedsCount = 0,
    ): array {
        $includedChildren = (int) ($profile->included_children ?? 1);
        $regularChildren = max(0, $childrenCount - $specialNeedsCount);
        $extraRegularChildren = max(0, $regularChildren - $includedChildren);

        $baseAmount = $duration * (float) $profile->hourly_rate;
        $extraAmount = $duration * $extraRegularChildren * (float) ($profile->extra_child_fee ?? 0);
        $specialNeedsAmount = $duration * $specialNeedsCount * (float) ($profile->special_needs_rate ?? 0);

        return [
            'total' => $baseAmount + $extraAmount + $specialNeedsAmount,
            'base' => $baseAmount,
            'extra' => $extraAmount,
            'special' => $specialNeedsAmount,
        ];
    }

    public function validateAvailability(Booking $booking, ?string $newDate = null, ?string $newStartTime = null, ?string $newEndTime = null, ?int $childrenCount = null): ?string
    {
        return $this->validateAvailabilityForSitter(
            $booking->sitter_id,
            $newDate ?? $booking->date->toDateString(),
            $newStartTime ?? $booking->start_time,
            $newEndTime ?? $booking->end_time,
            $booking->id,
            $childrenCount ?? $booking->children_count ?? 1,
        );
    }

    public function validateAvailabilityForSitter(int $sitterId, string $date, string $startTime, string $endTime, ?int $excludeBookingId = null, int $childrenCount = 1): ?string
    {
        $sitter = User::where('role', 'babysitter')
            ->where('verification_status', 'verified')
            ->with('babysitterProfile')
            ->find($sitterId);

        if (!$sitter) return 'This babysitter is no longer available.';
        if (!$sitter->babysitterProfile?->is_available) return 'This babysitter is currently unavailable.';

        $profile = $sitter->babysitterProfile;

        $absoluteMax = $profile->absolute_max_children;
        if ($absoluteMax !== null && $childrenCount > $absoluteMax) {
            return 'This sitter can accept a maximum of ' . $absoluteMax . ' children.';
        }

        $dayOfWeek = (int) date('w', strtotime($date));

        $availability = $profile->availability ?? [];
        $daySlots = array_filter($availability, fn($slot) => (int) ($slot['dayOfWeek'] ?? $slot['day_of_week'] ?? 0) === $dayOfWeek);

        if (empty($daySlots)) {
            return 'The sitter is not available on this day of the week.';
        }

        $withinWorkingHours = false;
        foreach ($daySlots as $slot) {
            $slotStart = $slot['startTime'] ?? $slot['start_time'] ?? '09:00';
            $slotEnd = $slot['endTime'] ?? $slot['end_time'] ?? '17:00';
            $bookingStart = \Carbon\Carbon::parse($startTime);
            $bookingEnd = \Carbon\Carbon::parse($endTime);
            $slotStartTime = \Carbon\Carbon::parse($slotStart);
            $slotEndTime = \Carbon\Carbon::parse($slotEnd);
            if ($bookingStart->greaterThanOrEqualTo($slotStartTime) && $bookingEnd->lessThanOrEqualTo($slotEndTime)) {
                $withinWorkingHours = true;
                break;
            }
        }

        if (!$withinWorkingHours) {
            return 'The selected time is outside the sitter\'s working hours.';
        }

        $overlapping = Booking::query()
            ->where('sitter_id', $sitterId)
            ->whereDate('date', $date)
            ->whereIn('status', ['pending', 'confirmed', 'in_progress'])
            ->when($excludeBookingId, fn($q) => $q->where('id', '!=', $excludeBookingId))
            ->where(function ($query) use ($startTime, $endTime): void {
                $query
                    ->whereBetween('start_time', [$startTime, $endTime])
                    ->orWhereBetween('end_time', [$startTime, $endTime])
                    ->orWhere(function ($q) use ($startTime, $endTime): void {
                        $q->where('start_time', '<=', $startTime)
                          ->where('end_time', '>=', $endTime);
                    });
            })
            ->exists();

        if ($overlapping) {
            $existingBooking = Booking::where('sitter_id', $sitterId)
                ->whereDate('date', $date)
                ->whereIn('status', ['pending', 'confirmed', 'in_progress'])
                ->when($excludeBookingId, fn($q) => $q->where('id', '!=', $excludeBookingId))
                ->where(function ($query) use ($startTime, $endTime): void {
                    $query
                        ->whereBetween('start_time', [$startTime, $endTime])
                        ->orWhereBetween('end_time', [$startTime, $endTime])
                        ->orWhere(function ($q) use ($startTime, $endTime): void {
                            $q->where('start_time', '<=', $startTime)
                              ->where('end_time', '>=', $endTime);
                        });
                })
                ->first(['start_time', 'end_time']);

            if ($existingBooking) {
                return "The selected time {$startTime}–{$endTime} overlaps with an existing booking ({$existingBooking->start_time}–{$existingBooking->end_time}). Please choose a different time slot.";
            }

            return 'The selected time slot overlaps with an existing booking. Please choose a different time.';
        }

        $maxDailyBookings = 3;
        $existingCount = Booking::query()
            ->where('sitter_id', $sitterId)
            ->whereDate('date', $date)
            ->whereIn('status', ['pending', 'confirmed', 'in_progress'])
            ->when($excludeBookingId, fn($q) => $q->where('id', '!=', $excludeBookingId))
            ->count();

        if ($existingCount >= $maxDailyBookings) return 'This sitter is already fully booked on this date.';

        return null;
    }

    public function transitionStatus(Booking $booking, string $newStatus, ?User $changedBy = null, ?string $reason = null, bool $isGroupSession = false): Booking
    {
        $expectedStatus = $booking->status;

        DB::transaction(function () use ($booking, $newStatus, $expectedStatus, $changedBy, $reason, $isGroupSession): void {
            $fresh = Booking::query()
                ->where('id', $booking->id)
                ->lockForUpdate()
                ->first();

            if (!$fresh || $fresh->status !== $expectedStatus) {
                throw new \RuntimeException('Booking status was modified by another request.');
            }

            $oldStatus = $fresh->status;

            if (!in_array($newStatus, ['in_progress', 'rebooked', 'pending'])) {
                $validTransitions = [
                    'pending' => ['confirmed', 'cancelled', 'expired', 'rejected'],
                    'confirmed' => ['in_progress', 'completed', 'cancelled', 'pending'],
                    'in_progress' => ['completed'],
                    'completed' => [],
                    'cancelled' => [],
                    'rejected' => [],
                    'expired' => [],
                ];
                $allowed = $validTransitions[$oldStatus] ?? [];
                if (!in_array($newStatus, $allowed, true)) {
                    throw new \InvalidArgumentException("Transition from {$oldStatus} to {$newStatus} is not allowed.");
                }
            }

            $timestamps = [
                'confirmed' => 'confirmed_at',
                'completed' => 'completed_at',
                'cancelled' => 'cancelled_at',
                'rejected' => 'rejected_at',
                'expired' => 'expired_at',
                'in_progress' => 'in_progress_at',
            ];

            $updateData = ['status' => $newStatus];
            if (isset($timestamps[$newStatus])) {
                $updateData[$timestamps[$newStatus]] = now();
            }
            if ($newStatus === 'pending' && $oldStatus === 'confirmed') {
                $updateData['confirmed_at'] = null;
            }

            $booking->update($updateData);

            if ($newStatus === 'completed') {
                $profile = $booking->sitter->babysitterProfile;
                if ($profile) {
                    $profile->increment('total_earnings', (int) $booking->total_amount);
                    if (!$isGroupSession) {
                        $profile->increment('completed_bookings');
                    }
                }
            }

            if ($newStatus === 'cancelled' && !$isGroupSession) {
                $booking->sitter->babysitterProfile?->increment('cancelled_bookings');
            }

            BookingStatusHistory::create([
                'booking_id' => $booking->id,
                'from_status' => $oldStatus,
                'to_status' => $newStatus,
                'changed_by_id' => $changedBy?->id,
                'reason' => $reason,
            ]);

            $history = $booking->status_history ?? [];
            $history[] = [
                'from' => $oldStatus,
                'to' => $newStatus,
                'timestamp' => now()->toISOString(),
                'reason' => $reason,
            ];
            $booking->updateQuietly(['status_history' => $history]);

            $this->timelineService->recordStatusChange(
                $booking, $oldStatus, $newStatus,
                actorId: $changedBy?->id, reason: $reason,
            );

            if ($newStatus === 'cancelled') {
                $role = $changedBy && $changedBy->id === $booking->customer_id ? 'customer' : 'sitter';
                $this->cancellationService->recordCancellation(
                    $booking, $role,
                    reason: $reason, actorId: $changedBy?->id,
                );
            }

            if (!$isGroupSession) {
                $this->notifyBookingChange($booking, $newStatus, $oldStatus);
            }
        });

        return $booking->fresh();
    }

    private function notifyBookingChange(Booking $booking, string $newStatus, string $oldStatus): void
    {
        $templates = [
            'pending' => ['title' => 'booking_submitted_title', 'body' => 'booking_submitted_body'],
            'confirmed' => ['title' => 'booking_confirmed_title', 'body' => 'booking_confirmed_body'],
            'cancelled' => ['title' => 'booking_cancelled_title', 'body' => 'booking_cancelled_body'],
            'completed' => ['title' => 'booking_completed_title', 'body' => 'booking_completed_body'],
            'rejected' => ['title' => 'booking_rejected_title', 'body' => 'booking_rejected_body'],
            'expired' => ['title' => 'booking_expired_title', 'body' => 'booking_expired_body'],
            'in_progress' => ['title' => 'booking_in_progress_title', 'body' => 'booking_in_progress_body'],
        ];

        $isRevision = $newStatus === 'pending' && $oldStatus === 'confirmed';
        if ($isRevision) {
            $templates['pending'] = ['title' => 'booking_updated_title', 'body' => 'booking_updated_body'];
        }

        $template = $templates[$newStatus] ?? null;
        if (!$template) return;

        $customer = $booking->customer;
        $sitter = $booking->sitter;

        $replacements = [
            '{sitter_name}' => $sitter->name,
            '{customer_name}' => $customer->name,
            '{booking_id}' => (string) $booking->id,
            '{date}' => $booking->date?->format('M j, Y') ?? '',
            '{time}' => substr((string) $booking->start_time, 0, 5),
            '{children_count}' => (string) ($booking->children_count ?? 1),
            '{total_amount}' => number_format((float) $booking->total_amount, 0),
        ];

        if ($customer) {
            $customer->notify(new BookingNotification(
                $template['title'],
                $template['body'],
                $replacements,
                $booking,
                $newStatus
            ));
        }

        if ($sitter) {
            $shouldNotifySitter = match(true) {
                $isRevision => true,
                default => in_array($newStatus, ['pending', 'cancelled', 'confirmed', 'in_progress', 'completed', 'rejected']),
            };

            if ($shouldNotifySitter) {
                $sitterTitle = match(true) {
                    $isRevision => 'booking_updated_title',
                    $newStatus === 'pending' => 'new_booking_request_title',
                    $newStatus === 'confirmed' => 'booking_confirmed_sitter_title',
                    $newStatus === 'cancelled' => 'booking_cancelled_sitter_title',
                    $newStatus === 'in_progress' => 'booking_in_progress_sitter_title',
                    $newStatus === 'completed' => 'booking_completed_sitter_title',
                    $newStatus === 'rejected' => 'booking_rejected_sitter_title',
                    default => $template['title'],
                };
                $sitterBody = match(true) {
                    $isRevision => 'booking_updated_body',
                    $newStatus === 'pending' => 'new_booking_request_body',
                    $newStatus === 'confirmed' => 'booking_confirmed_sitter_body',
                    $newStatus === 'cancelled' => 'booking_cancelled_sitter_body',
                    $newStatus === 'in_progress' => 'booking_in_progress_sitter_body',
                    $newStatus === 'completed' => 'booking_completed_sitter_body',
                    $newStatus === 'rejected' => 'booking_rejected_sitter_body',
                    default => $template['body'],
                };
                $sitter->notify(new BookingNotification(
                    $sitterTitle,
                    $sitterBody,
                    $replacements,
                    $booking,
                    $newStatus
                ));
            }
        }
    }
}
