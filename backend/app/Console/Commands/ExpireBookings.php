<?php

namespace App\Console\Commands;

use App\Models\Booking;
use App\Models\User;
use App\Services\BookingGroupService;
use App\Services\BookingService;
use Illuminate\Console\Command;

final class ExpireBookings extends Command
{
    protected $signature = 'bookings:expire';
    protected $description = 'Auto-cancel pending bookings past their confirmation deadline or booking date';

    public function __construct(
        private readonly BookingGroupService $bookingGroupService,
    ) {
        parent::__construct();
    }

    public function handle(BookingService $bookingService): int
    {
        $systemUser = User::where('role', 'admin')->first();
        $count = 0;

        $queries = [
            'Confirmation deadline passed — the sitter did not respond in time.' => Booking::query()
                ->where('status', 'pending')
                ->whereNotNull('confirmation_deadline')
                ->where('confirmation_deadline', '<', now()),

            'Booking date has passed — no response from the sitter.' => Booking::query()
                ->where('status', 'pending')
                ->where('date', '<', now()->toDateString()),

            'Booking time has passed — no response from the sitter.' => Booking::query()
                ->where('status', 'pending')
                ->where('date', '=', now()->toDateString())
                ->where('end_time', '<=', now()->format('H:i:s')),
        ];

        $processedGroups = [];

        foreach ($queries as $reason => $query) {
            foreach ($query->get() as $booking) {
                try {
                    if ($booking->booking_group_id) {
                        $isExpired = $booking->date->isPast()
                            || ($booking->end_time && $booking->end_time <= now()->format('H:i:s') && $booking->date->isToday());

                        if (!$isExpired) {
                            continue;
                        }

                        $bookingService->transitionStatus($booking, 'cancelled', $systemUser, $reason, true);

                        if (!in_array($booking->booking_group_id, $processedGroups, true)) {
                            $processedGroups[] = $booking->booking_group_id;
                            $this->bookingGroupService->handleCancellation($booking, $systemUser, $reason);
                        }

                        $count++;
                        continue;
                    }

                    $bookingService->transitionStatus($booking, 'cancelled', $systemUser, $reason);
                    $count++;
                } catch (\Throwable $e) {
                    $this->error("Failed to auto-cancel booking #{$booking->id}: {$e->getMessage()}");
                }
            }
        }

        $this->info("Auto-cancelled {$count} expired booking(s).");

        return self::SUCCESS;
    }
}
