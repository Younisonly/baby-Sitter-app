<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\BookingResource;
use App\Traits\ApiResponse;
use App\Models\Booking;
use App\Models\BookingTracking;
use App\Notifications\BookingNotification;
use App\Services\BookingService;
use App\Services\BookingGroupService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class SessionController extends Controller
{
    use ApiResponse;

    public function generateStartQr(Request $request, Booking $booking): JsonResponse
    {
        if ($booking->sitter_id !== $request->user()->id) {
            return $this->error('Only the assigned sitter can generate the start QR code.', 403);
        }

        if ($booking->status !== 'confirmed') {
            return $this->error('Booking must be confirmed before starting a session. Current status: ' . $booking->status, 422);
        }

        $isExpired = $booking->date->isPast()
            || ($booking->end_time && $booking->end_time <= now()->format('H:i:s') && $booking->date->isToday());

        if ($isExpired) {
            $bookingService = app(BookingService::class);
            $bookingService->transitionStatus(
                $booking, 'cancelled', $request->user(),
                'Booking date has passed — auto-cancelled before session start.',
                $booking->booking_group_id !== null,
            );

            if ($booking->booking_group_id) {
                app(BookingGroupService::class)->handleCancellation($booking, $request->user());

                $nextBooking = Booking::where('booking_group_id', $booking->booking_group_id)
                    ->where('id', '!=', $booking->id)
                    ->where('status', 'confirmed')
                    ->whereDate('date', '>=', now()->toDateString())
                    ->orderBy('date')
                    ->first();

                if ($nextBooking) {
                    return $this->generateStartQr($request, $nextBooking);
                }

                return $this->error('This session has expired. No future sessions available in this group.', 422);
            }

            return $this->error('This booking has been cancelled because its date has passed.', 422);
        }

        if ($booking->booking_group_id) {
            $activeInGroup = Booking::where('booking_group_id', $booking->booking_group_id)
                ->where('id', '!=', $booking->id)
                ->whereIn('session_status', ['active', 'end_qr_generated'])
                ->exists();
            if ($activeInGroup) {
                return $this->error('Another session in this group is already active. Please complete it first.', 422);
            }
        }

        $booking = Booking::lockForUpdate()->findOrFail($booking->id);

        $qrToken = Str::random(64) . ':' . $booking->id . ':' . time();
        $hashedToken = hash('sha256', $qrToken);

        $booking->updateQuietly([
            'qr_start_token' => $hashedToken,
            'session_status' => 'start_qr_generated',
        ]);

        $cacheKey = 'session_ready_notified_' . $booking->id;
        $shouldNotify = \Illuminate\Support\Facades\Cache::add($cacheKey, true, now()->addMinutes(5));

        if ($booking->customer && $shouldNotify) {
            $booking->customer->notify(new BookingNotification(
                'session_ready_title',
                'session_ready_body',
                [
                    '{sitter_name}' => $booking->sitter->name,
                    '{booking_id}' => (string) $booking->id,
                ],
                $booking,
                'session_ready',
            ));
        }

        $now = now();
        $bookingDate = $booking->date instanceof Carbon ? $booking->date : Carbon::parse($booking->date);
        $isOutOfSchedule = !$now->isSameDay($bookingDate) || $now->lt($booking->start_time) || $now->gt($booking->end_time);

        return $this->success([
            'qrToken' => $qrToken,
            'bookingId' => (string) $booking->id,
            'expiresAt' => $now->copy()->addMinutes(5)->toISOString(),
            'isOutOfSchedule' => $isOutOfSchedule,
        ], 'Start QR code generated successfully');
    }

    public function scanStartQr(Request $request): JsonResponse
    {
        $request->validate([
            'qr_token' => ['required', 'string', 'min:77', 'max:86'],
            'notes' => ['nullable', 'string', 'max:500'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
        ]);

        $qrToken = $request->input('qr_token');
        $parts = explode(':', $qrToken);

        if (count($parts) !== 3) {
            return $this->error('Invalid QR code format.', 422);
        }

        $bookingId = (int) $parts[1];
        $tokenTime = (int) $parts[2];
        $hashedToken = hash('sha256', $qrToken);

        if (time() - $tokenTime > 300) {
            return $this->error('This QR code has expired. Please request a new one.', 422);
        }

        $booking = Booking::lockForUpdate()->findOrFail($bookingId);

        if ($booking->customer_id !== $request->user()->id) {
            return $this->error('Only the customer who made this booking can scan this QR code.', 403);
        }

        if ($booking->session_status !== 'start_qr_generated') {
            return $this->error('Invalid session state. Current status: ' . $booking->session_status, 422);
        }

        if ($booking->qr_start_token !== $hashedToken) {
            return $this->error('Invalid QR code. Please request a new one.', 422);
        }

        $isExpired = $booking->date->isPast()
            || ($booking->end_time && $booking->end_time <= now()->format('H:i:s') && $booking->date->isToday());

        if ($isExpired) {
            return $this->error('This session date has passed and cannot be started.', 422);
        }

        $now = now();

        $updateData = [
            'session_status' => 'active',
            'status' => 'in_progress',
            'in_progress_at' => $now,
            'session_started_at' => $now,
            'gps_started_at' => $now,
            'qr_start_token' => null,
        ];

        if ($request->filled('session_notes')) {
            $updateData['session_notes'] = $request->input('session_notes');
        }

        $booking->update($updateData);

        $history = (array) ($booking->status_history ?? []);
        $history[] = ['from' => 'confirmed', 'to' => 'in_progress', 'timestamp' => $now->toISOString(), 'reason' => 'Session started via QR scan'];
        $booking->updateQuietly(['status_history' => $history]);

        if ($request->filled('latitude') && $request->filled('longitude')) {
            BookingTracking::create([
                'booking_id' => $booking->id,
                'latitude' => $request->input('latitude'),
                'longitude' => $request->input('longitude'),
                'address' => $request->input('address'),
                'recorded_at' => $now,
            ]);
        }

        if ($booking->booking_group_id) {
            app(\App\Services\BookingGroupService::class)->onBookingStatusChange($booking);
        }

        if ($booking->sitter) {
            $booking->sitter->notify(new BookingNotification(
                'session_started_sitter_title',
                'session_started_sitter_body',
                [
                    '{customer_name}' => $booking->customer->name,
                    '{booking_id}' => (string) $booking->id,
                ],
                $booking,
                'session_started',
            ));
        }

        if ($booking->customer) {
            $booking->customer->notify(new BookingNotification(
                'session_started_title',
                'session_started_body',
                [
                    '{sitter_name}' => $booking->sitter->name,
                    '{booking_id}' => (string) $booking->id,
                ],
                $booking,
                'session_started',
            ));
        }

        return $this->success(
            BookingResource::make($booking->fresh()->load(['customer', 'sitter.babysitterProfile'])),
            'Session started successfully',
        );
    }

    public function generateEndQr(Request $request, Booking $booking): JsonResponse
    {
        if ($booking->sitter_id !== $request->user()->id) {
            return $this->error('Only the assigned sitter can generate the end QR code.', 403);
        }

        if (!in_array($booking->session_status, ['active', 'end_qr_generated'], true)) {
            return $this->error('Session must be active to generate end QR. Current status: ' . $booking->session_status, 422);
        }

        $booking = Booking::lockForUpdate()->findOrFail($booking->id);

        $qrToken = Str::random(64) . ':' . $booking->id . ':' . time();
        $hashedToken = hash('sha256', $qrToken);

        $booking->updateQuietly([
            'qr_end_token' => $hashedToken,
            'session_status' => 'end_qr_generated',
        ]);

        $cacheKey = 'session_end_ready_notified_' . $booking->id;
        $shouldNotify = \Illuminate\Support\Facades\Cache::add($cacheKey, true, now()->addMinutes(5));

        if ($booking->customer && $shouldNotify) {
            $booking->customer->notify(new BookingNotification(
                'session_end_ready_title',
                'session_end_ready_body',
                [
                    '{sitter_name}' => $booking->sitter->name,
                    '{booking_id}' => (string) $booking->id,
                ],
                $booking,
                'session_end_ready',
            ));
        }

        return $this->success([
            'qrToken' => $qrToken,
            'bookingId' => (string) $booking->id,
            'expiresAt' => now()->addMinutes(5)->toISOString(),
        ], 'End QR code generated successfully');
    }

    public function scanEndQr(Request $request): JsonResponse
    {
        $request->validate([
            'qr_token' => ['required', 'string', 'min:77', 'max:86'],
        ]);

        $qrToken = $request->input('qr_token');
        $parts = explode(':', $qrToken);

        if (count($parts) !== 3) {
            return $this->error('Invalid QR code format.', 422);
        }

        $bookingId = (int) $parts[1];
        $tokenTime = (int) $parts[2];
        $hashedToken = hash('sha256', $qrToken);

        if (time() - $tokenTime > 300) {
            return $this->error('This QR code has expired. Please request a new one.', 422);
        }

        $booking = Booking::lockForUpdate()->findOrFail($bookingId);

        if ($booking->customer_id !== $request->user()->id) {
            return $this->error('Only the customer who made this booking can scan this QR code.', 403);
        }

        if ($booking->session_status !== 'end_qr_generated') {
            return $this->error('Invalid session state. Current status: ' . $booking->session_status, 422);
        }

        if ($booking->qr_end_token !== $hashedToken) {
            return $this->error('Invalid QR code. Please request a new one.', 422);
        }

        $now = now();

        $sessionStart = $booking->session_started_at;
        $actualMinutes = $sessionStart ? $sessionStart->diffInMinutes($now) : 0;
        $expectedMinutes = ($booking->duration ?? 0) * 60;
        $overtimeMinutes = max(0, $actualMinutes - $expectedMinutes);
        $actualHours = round($actualMinutes / 60, 2);
        $expectedHours = (float) ($booking->duration ?? 0);

        $overtimeCost = 0;
        if ($overtimeMinutes > 0 && $booking->sitter->babysitterProfile) {
            $profile = $booking->sitter->babysitterProfile;
            $overtimeHours = $overtimeMinutes / 60;
            $overtimeCost = (int) round($overtimeHours * (float) $profile->hourly_rate * 1.25);
        }

        $isGroupSession = $booking->booking_group_id !== null;

        $updateData = [
            'session_status' => 'completed',
            'session_ended_at' => $now,
            'gps_ended_at' => $now,
            'qr_end_token' => null,
            'overtime_minutes' => $overtimeMinutes,
            'overtime_cost' => $overtimeCost,
            'expected_hours' => $expectedHours,
            'actual_hours' => $actualHours,
        ];

        if ($isGroupSession) {
            // For group bookings: mark day as complete but keep booking in_progress
            $updateData['is_day_completed'] = true;
            $updateData['day_completed_at'] = $now;
        } else {
            // For single-day bookings: mark booking completed
            $updateData['status'] = 'completed';
            $updateData['completed_at'] = $now;
        }

        $booking->update($updateData);

        if ($overtimeMinutes > 0) {
            $profile = $booking->sitter->babysitterProfile;
            if ($profile) {
                $profile->increment('total_earnings', $overtimeCost);
            }
        }

        if ($isGroupSession && $booking->sitter && $booking->sitter->babysitterProfile) {
            $booking->sitter->babysitterProfile->increment('total_earnings', (int) $booking->total_amount);
        }

        $history = (array) ($booking->status_history ?? []);
        $history[] = [
            'from' => 'in_progress',
            'to' => $isGroupSession ? 'day_completed' : 'completed',
            'timestamp' => $now->toISOString(),
            'reason' => 'Session ended via QR scan' . ($overtimeMinutes > 0 ? " (+{$overtimeMinutes}min overtime)" : ''),
        ];
        $booking->updateQuietly(['status_history' => $history]);

        if ($isGroupSession) {
            app(\App\Services\BookingGroupService::class)->handleDayCompletion($booking);
        }

        $sitterReplacements = [
            '{customer_name}' => $booking->customer->name,
            '{booking_id}' => (string) $booking->id,
            '{actual_hours}' => (string) $actualHours,
            '{overtime}' => $overtimeMinutes > 0 ? " ({$overtimeMinutes}min overtime)" : '',
        ];

        $customerReplacements = [
            '{sitter_name}' => $booking->sitter->name,
            '{booking_id}' => (string) $booking->id,
            '{actual_hours}' => (string) $actualHours,
            '{overtime}' => $overtimeMinutes > 0 ? " ({$overtimeMinutes}min overtime, +SAR {$overtimeCost})" : '',
        ];

        $booking->sitter->notify(new BookingNotification(
            'session_ended_sitter_title',
            'session_ended_sitter_body',
            $sitterReplacements,
            $booking,
            'session_ended',
        ));

        $booking->customer->notify(new BookingNotification(
            'session_ended_title',
            'session_ended_body',
            $customerReplacements,
            $booking,
            'session_ended',
        ));

        return $this->success(
            BookingResource::make($booking->fresh()->load(['customer', 'sitter.babysitterProfile'])),
            'Session completed successfully',
        );
    }

    public function stopTracking(Request $request, Booking $booking): JsonResponse
    {
        if ($booking->sitter_id !== $request->user()->id) {
            return $this->error('Only the assigned sitter can stop location sharing.', 403);
        }

        if (!in_array($booking->session_status, ['active', 'end_qr_generated'], true)) {
            return $this->error('Session is not active.', 422);
        }

        $booking->updateQuietly([
            'gps_ended_at' => now(),
        ]);

        return $this->success([
            'gpsEndedAt' => $booking->gps_ended_at->toISOString(),
        ], 'Location sharing stopped');
    }

    public function resumeTracking(Request $request, Booking $booking): JsonResponse
    {
        if ($booking->sitter_id !== $request->user()->id) {
            return $this->error('Only the assigned sitter can resume location sharing.', 403);
        }

        if (!in_array($booking->session_status, ['active', 'end_qr_generated'], true)) {
            return $this->error('Session is not active.', 422);
        }

        $booking->updateQuietly([
            'gps_ended_at' => null,
        ]);

        return $this->success(null, 'Location sharing resumed');
    }

    public function refreshTracking(Request $request, Booking $booking): JsonResponse
    {
        if ($booking->customer_id !== $request->user()->id) {
            return $this->error('Only the customer can refresh location tracking.', 403);
        }

        if (!in_array($booking->session_status, ['active', 'end_qr_generated'], true)) {
            return $this->error('Session is not active.', 422);
        }

        $latest = $booking->latestTracking;

        if (!$latest) {
            return $this->error('No location data available yet.', 422);
        }

        $tracking = BookingTracking::create([
            'booking_id' => $booking->id,
            'latitude' => $latest->latitude,
            'longitude' => $latest->longitude,
            'address' => $latest->address,
            'speed' => $latest->speed,
            'battery' => $latest->battery,
            'recorded_at' => now(),
        ]);

        return $this->success([
            'latitude' => (float) $tracking->latitude,
            'longitude' => (float) $tracking->longitude,
            'address' => $tracking->address,
            'speed' => $tracking->speed ? (float) $tracking->speed : null,
            'battery' => $tracking->battery ? (int) $tracking->battery : null,
            'recordedAt' => $tracking->recorded_at->toISOString(),
        ], 'Location refreshed');
    }

    public function storeTracking(Request $request, Booking $booking): JsonResponse
    {
        if ($booking->customer_id !== $request->user()->id && $booking->sitter_id !== $request->user()->id) {
            return $this->error('You are not part of this booking.', 403);
        }

        if (!in_array($booking->session_status, ['active', 'start_qr_generated', 'end_qr_generated'], true)) {
            return $this->error('Session is not active.', 422);
        }

        $request->validate([
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'address' => ['nullable', 'string', 'max:255'],
            'speed' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'battery' => ['nullable', 'integer', 'min:0', 'max:100'],
        ]);

        $tracking = BookingTracking::create([
            'booking_id' => $booking->id,
            'latitude' => $request->input('latitude'),
            'longitude' => $request->input('longitude'),
            'address' => $request->input('address'),
            'speed' => $request->input('speed'),
            'battery' => $request->input('battery'),
            'recorded_at' => now(),
        ]);

        if ($request->user()->id === $booking->customer_id) {
            $booking->customer->notify(new BookingNotification(
                'location_updated_title',
                'location_updated_body',
                [
                    '{sitter_name}' => $booking->sitter->name,
                ],
                $booking,
                'location_updated',
            ));
        }

        $shouldWarn = false;
        if ($request->filled('address') && $booking->address && $booking->address !== $request->input('address')) {
            $shouldWarn = true;
        }

        return $this->success([
            'id' => $tracking->id,
            'recordedAt' => $tracking->recorded_at->toISOString(),
            'warn' => $shouldWarn,
        ], 'Location updated');
    }

    public function getTracking(Request $request, Booking $booking): JsonResponse
    {
        if ($booking->customer_id !== $request->user()->id && $booking->sitter_id !== $request->user()->id) {
            return $this->error('You are not part of this booking.', 403);
        }

        $limit = $request->integer('limit', 100);
        $since = $request->input('since');

        $query = $booking->trackingPoints()
            ->select(['id', 'latitude', 'longitude', 'address', 'speed', 'battery', 'recorded_at'])
            ->latest('recorded_at')
            ->limit($limit);

        if ($since) {
            $query->where('recorded_at', '>', $since);
        }

        $points = $query->get()->map(fn($p) => [
            'latitude' => (float) $p->latitude,
            'longitude' => (float) $p->longitude,
            'address' => $p->address,
            'speed' => $p->speed ? (float) $p->speed : null,
            'battery' => $p->battery ? (int) $p->battery : null,
            'recordedAt' => $p->recorded_at?->toISOString(),
        ])->values();

        $latest = $booking->latestTracking;

        $duration = null;
        if ($booking->session_started_at) {
            $duration = $booking->session_started_at->diffInMinutes(now());
            if ($booking->session_ended_at) {
                $duration = $booking->session_started_at->diffInMinutes($booking->session_ended_at);
            }
        }

        return $this->success([
            'tracking' => $points,
            'latest' => $latest ? [
                'latitude' => (float) $latest->latitude,
                'longitude' => (float) $latest->longitude,
                'address' => $latest->address,
                'speed' => $latest->speed ? (float) $latest->speed : null,
                'battery' => $latest->battery ? (int) $latest->battery : null,
                'recorded_at' => $latest->recorded_at->toISOString(),
            ] : null,
            'sessionDurationMinutes' => $duration,
            'bookingAddress' => $booking->address,
        ], 'Tracking data retrieved');
    }

    public function sessionStatus(Request $request, Booking $booking): JsonResponse
    {
        if ($booking->customer_id !== $request->user()->id && $booking->sitter_id !== $request->user()->id) {
            return $this->error('You are not part of this booking.', 403);
        }

        $duration = null;
        if ($booking->session_started_at) {
            $duration = $booking->session_started_at->diffInMinutes(now());
            if ($booking->session_ended_at) {
                $duration = $booking->session_started_at->diffInMinutes($booking->session_ended_at);
            }
        }

        $latest = $booking->latestTracking;

        return $this->success([
            'sessionStatus' => $booking->session_status,
            'sessionStartedAt' => $booking->session_started_at?->toISOString(),
            'sessionEndedAt' => $booking->session_ended_at?->toISOString(),
            'gpsStartedAt' => $booking->gps_started_at?->toISOString(),
            'gpsEndedAt' => $booking->gps_ended_at?->toISOString(),
            'durationMinutes' => $duration,
            'expectedHours' => (float) ($booking->duration ?? 0),
            'actualHours' => (float) ($booking->actual_hours ?? 0),
            'overtimeMinutes' => (int) ($booking->overtime_minutes ?? 0),
            'overtimeCost' => (int) ($booking->overtime_cost ?? 0),
            'latestLocation' => $latest ? [
                'latitude' => (float) $latest->latitude,
                'longitude' => (float) $latest->longitude,
                'address' => $latest->address,
                'speed' => $latest->speed ? (float) $latest->speed : null,
                'battery' => $latest->battery ? (int) $latest->battery : null,
                'recordedAt' => $latest->recorded_at?->toISOString(),
            ] : null,
        ], 'Session status');
    }

    public function forceStop(Request $request, Booking $booking): JsonResponse
    {
        if ($booking->customer_id !== $request->user()->id && $booking->sitter_id !== $request->user()->id) {
            return $this->error('You are not part of this booking.', 403);
        }

        if (!in_array($booking->session_status, ['active', 'end_qr_generated'])) {
            return $this->error('Session must be active to force stop. Current status: ' . $booking->session_status, 422);
        }

        $request->validate([
            'reason' => ['required', 'string', 'min:5', 'max:500'],
        ]);

        $now = now();

        $sessionStart = $booking->session_started_at;
        $actualMinutes = $sessionStart ? $sessionStart->diffInMinutes($now) : 0;
        $expectedMinutes = ($booking->duration ?? 0) * 60;
        $overtimeMinutes = max(0, $actualMinutes - $expectedMinutes);
        $actualHours = round($actualMinutes / 60, 2);
        $expectedHours = (float) ($booking->duration ?? 0);

        $overtimeCost = 0;
        if ($overtimeMinutes > 0 && $booking->sitter && $booking->sitter->babysitterProfile) {
            $profile = $booking->sitter->babysitterProfile;
            $overtimeHours = $overtimeMinutes / 60;
            $overtimeCost = (int) round($overtimeHours * (float) $profile->hourly_rate * 1.25);
        }

        $stoppedBy = $request->user()->id === $booking->sitter_id ? 'sitter' : 'customer';
        $sessionNote = '[Force stopped by ' . $stoppedBy . '] ' . $request->input('reason');
        $existingNotes = $booking->session_notes;
        $sessionNote = $existingNotes ? $existingNotes . "\n" . $sessionNote : $sessionNote;

        $isGroupSession = $booking->booking_group_id !== null;

        $updateData = [
            'session_status' => 'completed',
            'session_ended_at' => $now,
            'gps_ended_at' => $now,
            'overtime_minutes' => $overtimeMinutes,
            'overtime_cost' => $overtimeCost,
            'expected_hours' => $expectedHours,
            'actual_hours' => $actualHours,
            'session_notes' => $sessionNote,
        ];

        if ($isGroupSession) {
            $updateData['is_day_completed'] = true;
            $updateData['day_completed_at'] = $now;
        } else {
            $updateData['status'] = 'completed';
            $updateData['completed_at'] = $now;
        }

        $booking->update($updateData);

        if ($overtimeMinutes > 0 && $booking->sitter && $booking->sitter->babysitterProfile) {
            $booking->sitter->babysitterProfile->increment('total_earnings', $overtimeCost);
        }

        if ($isGroupSession && $booking->sitter && $booking->sitter->babysitterProfile) {
            $booking->sitter->babysitterProfile->increment('total_earnings', (int) $booking->total_amount);
        }

        $history = (array) ($booking->status_history ?? []);
        $history[] = [
            'from' => 'in_progress',
            'to' => $isGroupSession ? 'day_completed' : 'completed',
            'timestamp' => $now->toISOString(),
            'reason' => 'Session force stopped by ' . $stoppedBy . ': ' . $request->input('reason'),
        ];
        $booking->updateQuietly(['status_history' => $history]);

        if ($isGroupSession) {
            app(\App\Services\BookingGroupService::class)->handleDayCompletion($booking);
        }

        $booking->sitter->notify(new BookingNotification(
            'session_ended_sitter_title',
            'session_ended_sitter_body',
            [
                '{customer_name}' => $booking->customer->name,
                '{booking_id}' => (string) $booking->id,
                '{actual_hours}' => (string) $actualHours,
                '{overtime}' => $overtimeMinutes > 0 ? " ({$overtimeMinutes}min overtime)" : '',
            ],
            $booking,
            'session_ended',
        ));

        $booking->customer->notify(new BookingNotification(
            'session_ended_title',
            'session_ended_body',
            [
                '{sitter_name}' => $booking->sitter->name,
                '{booking_id}' => (string) $booking->id,
                '{actual_hours}' => (string) $actualHours,
                '{overtime}' => $overtimeMinutes > 0 ? " ({$overtimeMinutes}min overtime, +SAR {$overtimeCost})" : '',
            ],
            $booking,
            'session_ended',
        ));

        return $this->success(
            BookingResource::make($booking->fresh()->load(['customer', 'sitter.babysitterProfile'])),
            'Session force stopped successfully',
        );
    }

    public function activeSession(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        // First try to find a currently active session
        $booking = Booking::where(fn($q) => $q
            ->where('customer_id', $userId)
            ->orWhere('sitter_id', $userId))
            ->whereIn('session_status', ['active', 'end_qr_generated'])
            ->where('status', 'in_progress')
            ->with(['customer', 'sitter.babysitterProfile'])
            ->first();

        if ($booking) {
            return $this->success(
                BookingResource::make($booking),
                'Active session found',
            );
        }

        // For group bookings, check if there's a confirmed session ready to start
        $nextGroupBooking = Booking::where(fn($q) => $q
            ->where('customer_id', $userId)
            ->orWhere('sitter_id', $userId))
            ->where('status', 'confirmed')
            ->where('session_status', '!=', 'completed')
            ->where(function ($q) {
                $q->whereDate('date', '>', now()->toDateString())
                  ->orWhere(function ($q) {
                      $q->whereDate('date', '=', now()->toDateString())
                        ->whereTime('end_time', '>', now()->format('H:i:s'));
                  });
            })
            ->whereHas('bookingGroup', fn($q) => $q
                ->whereIn('status', ['confirmed', 'in_progress']))
            ->with(['customer', 'sitter.babysitterProfile', 'bookingGroup'])
            ->orderBy('date')
            ->first();

        if ($nextGroupBooking) {
            return $this->success(
                BookingResource::make($nextGroupBooking),
                'Next session available',
            );
        }

        return $this->success(null, 'No active session');
    }
}
