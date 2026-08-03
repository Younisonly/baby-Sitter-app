<?php

namespace App\Jobs;

use App\Models\Booking;
use App\Services\NotificationService;
use Carbon\Carbon;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class ProcessBookingReminderJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;

    public function __construct(
        private readonly int $bookingId,
        private readonly string $type, // '24h', '1h', '15min'
    ) {}

    public function handle(NotificationService $notificationService): void
    {
        $booking = Booking::with(['customer', 'sitter'])->find($this->bookingId);

        if (!$booking || !in_array($booking->status, ['confirmed', 'in_progress', 'pending'])) {
            return;
        }

        $date = Carbon::parse($booking->date)->format('d/m/Y');
        $time = Carbon::parse($booking->start_time)->format('h:i A');
        $type = $this->type;

        if ($type === '24h' || $type === '1h') {
            $actionKey = 'booking_reminder';
            $replacements = [
                'sitter_name' => $booking->sitter->name,
                'customer_name' => $booking->customer->name,
                'booking_id' => (string) $booking->id,
                'date' => $date,
                'time' => $time,
            ];

            $notificationService->send($booking->customer, $actionKey, $replacements, (string) $booking->id);

            if ($type === '1h') {
                $notificationService->send(
                    $booking->sitter,
                    'upcoming_booking_reminder',
                    $replacements,
                    (string) $booking->id,
                );
            }
        }
    }
}
