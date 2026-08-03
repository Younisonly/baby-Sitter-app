<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\BookingGroup;
use App\Models\User;
use App\Notifications\BookingNotification;
use Illuminate\Support\Facades\DB;

final class BookingGroupService
{
    public function __construct(
        private readonly CancellationService $cancellationService,
    ) {}

    public function createFromBookings(array $bookings, string $groupId, User $customer, User $sitter): BookingGroup
    {
        $totalAmount = collect($bookings)->sum(fn(Booking $b) => (float) $b->total_amount);
        $baseAmount = collect($bookings)->sum(fn(Booking $b) => (float) ($b->base_amount ?? 0));
        $extraAmount = collect($bookings)->sum(fn(Booking $b) => (float) ($b->extra_amount ?? 0));
        $specialAmount = collect($bookings)->sum(fn(Booking $b) => (float) ($b->special_needs_amount ?? 0));

        $dates = collect($bookings)->pluck('date')->sort();

        $group = BookingGroup::create([
            'id' => $groupId,
            'customer_id' => $customer->id,
            'sitter_id' => $sitter->id,
            'total_amount' => $totalAmount,
            'base_amount' => $baseAmount,
            'extra_amount' => $extraAmount,
            'special_needs_amount' => $specialAmount,
            'session_count' => count($bookings),
            'completed_count' => 0,
            'cancelled_count' => 0,
            'first_date' => $dates->first(),
            'last_date' => $dates->last(),
            'status' => 'pending',
        ]);

        return $group;
    }

    public function deriveStatus(BookingGroup $group): string
    {
        $bookings = $group->bookings()->get(['status', 'is_day_completed']);
        $statuses = $bookings->pluck('status');

        if ($statuses->every(fn($s) => $s === 'cancelled')) return 'cancelled';
        if ($statuses->every(fn($s) => $s === 'rejected')) return 'rejected';
        if ($statuses->every(fn($s) => $s === 'expired')) return 'expired';

        $allComplete = $bookings->every(fn($b) => $b->status === 'completed' || $b->is_day_completed);
        if ($allComplete) return 'completed';

        $allTerminal = $statuses->every(fn($s) => in_array($s, ['completed', 'cancelled', 'rejected', 'expired']));

        if ($allTerminal) {
            return $statuses->contains('completed') ? 'completed' : 'cancelled';
        }

        if ($statuses->contains('in_progress')) return 'in_progress';
        if ($statuses->contains('confirmed')) return 'confirmed';
        if ($statuses->contains('pending')) return 'pending';

        return 'pending';
    }

    public function onBookingStatusChange(Booking $booking): void
    {
        if (!$booking->booking_group_id) return;

        $group = BookingGroup::find($booking->booking_group_id);
        if (!$group) return;

        $freshBooking = $booking->fresh();
        $newStatus = $freshBooking->status;

        if ($newStatus === 'completed') {
            // Handled by handleDayCompletion for group bookings
        } elseif (in_array($newStatus, ['cancelled', 'rejected', 'expired'])) {
            $group->increment('cancelled_count');
        }

        $derived = $this->deriveStatus($group);
        $group->update(['status' => $derived]);
    }

    public function handleCancellation(Booking $booking, ?User $changedBy = null, ?string $reason = null): void
    {
        if (!$booking->booking_group_id) return;

        $group = BookingGroup::find($booking->booking_group_id);
        if (!$group) return;

        $this->onBookingStatusChange($booking);

        $group->refresh();
        $remainingActive = $group->bookings()
            ->whereIn('status', ['pending', 'confirmed', 'in_progress'])
            ->where('is_day_completed', false)
            ->count();

        if ($remainingActive === 0) {
            $this->notifyGroupChange($group, 'all_cancelled', $changedBy);
        } else {
            $this->notifyGroupChange($group, 'session_cancelled', $changedBy);
        }
    }

    public function handleDayCompletion(Booking $booking, ?User $changedBy = null): void
    {
        if (!$booking->booking_group_id) return;

        $group = BookingGroup::find($booking->booking_group_id);
        if (!$group) return;

        $group->increment('completed_count');

        $group->refresh();
        $allCompleted = $group->completed_count >= $group->session_count;

        if ($allCompleted) {
            DB::transaction(function () use ($group): void {
                $totalAmount = $group->bookings()->sum('total_amount');
                $group->bookings()->update([
                    'status' => 'completed',
                    'completed_at' => now(),
                ]);
                $group->update(['status' => 'completed']);

                $profile = $group->sitter?->babysitterProfile;
                if ($profile) {
                    $profile->increment('total_earnings', (int) $totalAmount);
                    $profile->increment('completed_bookings');
                }
            });
        } else {
            $derived = $this->deriveStatus($group);
            $group->update(['status' => $derived]);
        }

        $this->notifyGroupChange(
            $group,
            $allCompleted ? 'all_completed' : 'in_progress',
            $changedBy,
        );
    }

    public function notifyGroupChange(BookingGroup $group, string $event, ?User $changedBy = null): void
    {
        $customer = $group->customer;
        $sitter = $group->sitter;
        if (!$customer || !$sitter) return;

        $templates = match ($event) {
            'created' => [
                'customer' => ['title' => 'booking_submitted_title', 'body' => 'booking_submitted_body'],
                'sitter' => ['title' => 'new_booking_request_title', 'body' => 'new_booking_request_body'],
            ],
            'confirmed' => [
                'customer' => ['title' => 'booking_confirmed_title', 'body' => 'booking_confirmed_body'],
                'sitter' => ['title' => 'booking_confirmed_sitter_title', 'body' => 'booking_confirmed_sitter_body'],
            ],
            'in_progress' => [
                'customer' => ['title' => 'booking_in_progress_title', 'body' => 'booking_in_progress_body'],
                'sitter' => ['title' => 'booking_in_progress_sitter_title', 'body' => 'booking_in_progress_sitter_body'],
            ],
            'all_completed' => [
                'customer' => ['title' => 'booking_completed_title', 'body' => 'booking_completed_body'],
                'sitter' => ['title' => 'booking_completed_sitter_title', 'body' => 'booking_completed_sitter_body'],
            ],
            'session_cancelled' => [
                'customer' => ['title' => 'booking_cancelled_title', 'body' => 'booking_cancelled_partial_body'],
                'sitter' => ['title' => 'booking_cancelled_sitter_title', 'body' => 'booking_cancelled_partial_body'],
            ],
            'all_cancelled' => [
                'customer' => ['title' => 'booking_cancelled_title', 'body' => 'booking_cancelled_body'],
                'sitter' => ['title' => 'booking_cancelled_sitter_title', 'body' => 'booking_cancelled_sitter_body'],
            ],
            'rejected' => [
                'customer' => ['title' => 'booking_rejected_title', 'body' => 'booking_rejected_body'],
                'sitter' => ['title' => 'booking_rejected_sitter_title', 'body' => 'booking_rejected_sitter_body'],
            ],
            default => null,
        };

        if (!$templates) return;

        $firstBooking = $group->bookings()->first();
        if (!$firstBooking) return;

        $replacements = [
            '{sitter_name}' => $sitter->name,
            '{customer_name}' => $customer->name,
            '{date}' => $group->first_date?->format('M j, Y') ?? '',
            '{end_date}' => $group->last_date?->format('M j, Y') ?? '',
            '{session_count}' => (string) $group->session_count,
            '{completed_count}' => (string) $group->completed_count,
            '{total_amount}' => number_format((float) $group->total_amount, 0),
        ];

        $customer->notify(new BookingNotification(
            $templates['customer']['title'],
            $templates['customer']['body'],
            $replacements,
            $firstBooking,
            $event === 'all_completed' ? 'completed' : $event,
        ));

        $shouldNotifySitter = in_array($event, ['created', 'confirmed', 'in_progress', 'all_completed', 'session_cancelled', 'all_cancelled', 'rejected']);
        if ($shouldNotifySitter) {
            $sitter->notify(new BookingNotification(
                $templates['sitter']['title'],
                $templates['sitter']['body'],
                $replacements,
                $firstBooking,
                match($event) {
                    'created' => 'pending',
                    'confirmed' => 'confirmed',
                    'all_completed' => 'completed',
                    'session_cancelled', 'all_cancelled' => 'cancelled',
                    'rejected' => 'rejected',
                    default => $event,
                },
            ));
        }
    }

    public function calculateGroupRefund(BookingGroup $group, array $cancelledDates): array
    {
        $totalRefund = 0;
        $totalPenalty = 0;
        $refundDetails = [];

        $bookings = $group->bookings()
            ->whereIn('date', $cancelledDates)
            ->whereIn('status', ['pending', 'confirmed'])
            ->get();

        foreach ($bookings as $booking) {
            $refund = $this->cancellationService->calculateRefund($booking);
            $totalRefund += $refund['refund_amount'];
            $totalPenalty += $refund['penalty_amount'];
            $refundDetails[] = [
                'date' => $booking->date->toDateString(),
                'refund_amount' => $refund['refund_amount'],
                'penalty_amount' => $refund['penalty_amount'],
                'policy_name' => $refund['policy']['name'] ?? 'No Refund',
            ];
        }

        return [
            'total_refund' => round($totalRefund, 2),
            'total_penalty' => round($totalPenalty, 2),
            'cancelled_count' => count($bookings),
            'details' => $refundDetails,
        ];
    }

    public function syncFromGroup(BookingGroup $group): void
    {
        $bookings = $group->bookings;

        if ($bookings->isEmpty()) {
            $group->delete();
            return;
        }

        $dates = $bookings->pluck('date')->sort();

        $group->update([
            'total_amount' => $bookings->sum(fn(Booking $b) => (float) $b->total_amount),
            'base_amount' => $bookings->sum(fn(Booking $b) => (float) ($b->base_amount ?? 0)),
            'extra_amount' => $bookings->sum(fn(Booking $b) => (float) ($b->extra_amount ?? 0)),
            'special_needs_amount' => $bookings->sum(fn(Booking $b) => (float) ($b->special_needs_amount ?? 0)),
            'session_count' => $bookings->count(),
            'completed_count' => $bookings->where('status', 'completed')->count() + $bookings->where('is_day_completed', true)->where('status', '!=', 'completed')->count(),
            'cancelled_count' => $bookings->filter(fn(Booking $b) => in_array($b->status, ['cancelled', 'rejected', 'expired']))->count(),
            'first_date' => $dates->first(),
            'last_date' => $dates->last(),
            'status' => $this->deriveStatus($group),
        ]);
    }
}
