<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\CancelBookingRequest;
use App\Http\Requests\Api\V1\SitterBookingsRequest;
use App\Http\Requests\Api\V1\StoreBookingRequest;
use App\Http\Requests\Api\V1\StoreBookingReviewRequest;
use App\Http\Requests\Api\V1\StoreGroupReviewRequest;
use App\Http\Requests\Api\V1\UpdateBookingRequest;
use App\Http\Resources\BookingResource;
use App\Models\BabysitterProfile;
use App\Models\Booking;
use App\Models\BookingGroup;
use App\Models\User;
use App\Notifications\BookingNotification;
use App\Services\BookingGroupService;
use App\Services\BookingService;
use App\Services\CancellationService;
use App\Services\TimelineService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class BookingController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly BookingService $bookingService,
        private readonly BookingGroupService $bookingGroupService,
        private readonly CancellationService $cancellationService,
        private readonly TimelineService $timelineService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Booking::class);

        $status = $request->input('status');
        $user = $request->user();

        $query = Booking::query()
            ->with(['customer', 'sitter.babysitterProfile'])
            ->forUser($user);

        if ($role = $request->input('role')) {
            if ($role === 'customer') {
                $query->where('customer_id', $user->id);
            } elseif ($role === 'sitter') {
                $query->where('sitter_id', $user->id);
            }
        }

        if ($status && in_array($status, ['pending', 'confirmed', 'completed', 'cancelled', 'in_progress', 'rejected', 'expired'])) {
            $query->where(function ($q) use ($status) {
                $q->whereNull('booking_group_id')
                  ->where('bookings.status', $status)
                  ->orWhereIn('bookings.booking_group_id', function ($sub) use ($status) {
                      $sub->select('id')
                          ->from('booking_groups')
                          ->where('status', $status);
                  });
            });
        }

        if ($bookingGroupId = $request->input('booking_group_id')) {
            $query->where('booking_group_id', $bookingGroupId);
        }

        $sortField = $request->input('sort', 'created_at');
        $sortDir = $request->input('sort_dir', 'desc');
        $allowedSorts = ['created_at', 'date', 'updated_at', 'total_amount', 'status'];
        if (in_array($sortField, $allowedSorts)) {
            $query->orderBy($sortField, $sortDir === 'asc' ? 'asc' : 'desc');
        } else {
            $query->latest();
        }

        $bookings = $query->paginate($request->integer('per_page', 20));

        return $this->success(
            BookingResource::collection($bookings),
            'Bookings retrieved successfully',
        );
    }

    public function show(Booking $booking): JsonResponse
    {
        $this->authorize('view', $booking);

        $booking->load([
            'customer',
            'sitter.babysitterProfile',
            'statusHistories' => fn($q) => $q->latest(),
            'rescheduledFrom',
            'timelineEvents' => fn($q) => $q->latest()->with('actor:id,name'),
            'latestTracking',
        ]);

        $cancellationPolicy = $this->cancellationService->getRefundDetails($booking);

        return $this->success(
            BookingResource::make($booking),
            'Booking retrieved successfully',
        );
    }

    public function store(StoreBookingRequest $request): JsonResponse
    {
        if ($request->user()->id === (int) $request->input('sitter_id')) {
            return $this->error('You cannot book yourself. Please use a parent account to make a booking.', 422);
        }

        $this->authorize('create', Booking::class);

        $sitter = User::query()
            ->where('role', 'babysitter')
            ->where('verification_status', 'verified')
            ->with('babysitterProfile')
            ->findOrFail($request->integer('sitter_id'));

        if (! $sitter->babysitterProfile?->is_available) {
            return $this->error('This babysitter is currently unavailable.', 422);
        }

        if ($sitter->is_suspended) {
            return $this->error('This babysitter is currently unavailable.', 422);
        }

        $childrenCount = (int) ($request->input('children_count', 1));
        $specialNeedsCount = (int) ($request->input('special_needs_count', 0));
        $duration = (int) $request->integer('duration');

        $dates = $request->input('dates', []);
        $isMultiDay = !empty($dates);

        if ($isMultiDay) {
            return $this->storeMultiDay($request, $sitter, $dates, $childrenCount, $specialNeedsCount, $duration);
        }

        return $this->storeSingleDay($request, $sitter, $childrenCount, $specialNeedsCount, $duration);
    }

    private function storeSingleDay(Request $request, User $sitter, int $childrenCount, int $specialNeedsCount, int $duration): JsonResponse
    {
        $requestedDate = $request->date('date');

        if ($requestedDate->toDateString() === now()->toDateString() && $request->input('start_time') < now()->format('H:i')) {
            return $this->error('The selected start time has already passed. Please choose a future time.', 422);
        }

        $pricing = $this->bookingService->calculateTotal(
            $sitter->babysitterProfile,
            $duration,
            $childrenCount,
            $specialNeedsCount,
        );

        $booking = DB::transaction(function () use ($request, $sitter, $requestedDate, $childrenCount, $duration, $specialNeedsCount, $pricing): Booking {
            $overlapping = Booking::query()
                ->where('sitter_id', $sitter->id)
                ->whereDate('date', $requestedDate->toDateString())
                ->whereIn('status', ['pending', 'confirmed', 'in_progress'])
                ->where(function ($query) use ($request): void {
                    $query
                        ->whereBetween('start_time', [$request->input('start_time'), $request->input('end_time')])
                        ->orWhereBetween('end_time', [$request->input('start_time'), $request->input('end_time')])
                        ->orWhere(function ($q) use ($request): void {
                            $q->where('start_time', '<=', $request->input('start_time'))
                              ->where('end_time', '>=', $request->input('end_time'));
                        });
                })
                ->lockForUpdate()
                ->exists();

            if ($overlapping) {
                throw new \App\Exceptions\BookingConflictException('The selected time slot overlaps with an existing booking.');
            }

            $error = $this->bookingService->validateAvailabilityForSitter(
                $sitter->id,
                $requestedDate->toDateString(),
                $request->input('start_time'),
                $request->input('end_time'),
                childrenCount: $childrenCount,
            );
            if ($error) {
                throw new \App\Exceptions\BookingConflictException($error);
            }

            return Booking::create([
                'customer_id' => $request->user()->id,
                'sitter_id' => $sitter->id,
                'date' => $requestedDate->toDateString(),
                'start_time' => $request->input('start_time'),
                'end_time' => $request->input('end_time'),
                'duration' => $duration,
                'total_amount' => $pricing['total'],
                'base_amount' => $pricing['base'],
                'extra_amount' => $pricing['extra'],
                'special_needs_amount' => $pricing['special'],
                'status' => 'pending',
                'address' => $request->input('address'),
                'children_count' => $childrenCount,
                'special_needs_count' => $specialNeedsCount,
                'children_ages' => $request->input('children_ages', []),
                'children_names' => $request->input('children_names', []),
                'notes' => $request->input('notes'),
                'special_instructions' => $request->input('special_instructions'),
                'schedule_events' => $request->input('schedule_events', []),
                'status_history' => [[
                    'from' => null,
                    'to' => 'pending',
                    'timestamp' => now()->toISOString(),
                    'reason' => 'Booking created',
                ]],
            ]);
        });

        $booking->update(['confirmation_deadline' => now()->addMinutes(30)]);
        $this->bookingService->transitionStatus($booking, 'pending', $request->user());

        return $this->created(
            BookingResource::make($booking->load(['customer', 'sitter.babysitterProfile'])),
            'Booking created successfully',
        );
    }

    private function storeMultiDay(Request $request, User $sitter, array $dates, int $childrenCount, int $specialNeedsCount, int $duration): JsonResponse
    {
        $startTime = $request->input('start_time');
        $endTime = $request->input('end_time');

        $bookingGroupId = Str::uuid()->toString();

        $perDateTimes = $request->input('per_date_times', []);

        $bookings = DB::transaction(function () use ($request, $sitter, $dates, $childrenCount, $specialNeedsCount, $duration, $startTime, $endTime, $bookingGroupId, $perDateTimes): array {
            $bookedDates = [];

            foreach ($dates as $dateStr) {
                $date = Carbon::parse($dateStr);

                $dateStartTime = $perDateTimes[$dateStr]['start_time'] ?? $startTime;
                $dateEndTime = $perDateTimes[$dateStr]['end_time'] ?? $endTime;

                if ($date->toDateString() === now()->toDateString() && $dateStartTime < now()->format('H:i')) {
                    throw new \App\Exceptions\BookingConflictException(
                        "The selected start time for {$dateStr} has already passed. Please choose a future time."
                    );
                }

                $overlapping = Booking::query()
                    ->where('sitter_id', $sitter->id)
                    ->whereDate('date', $date->toDateString())
                    ->whereIn('status', ['pending', 'confirmed', 'in_progress'])
                    ->where(function ($query) use ($dateStartTime, $dateEndTime): void {
                        $query
                            ->whereBetween('start_time', [$dateStartTime, $dateEndTime])
                            ->orWhereBetween('end_time', [$dateStartTime, $dateEndTime])
                            ->orWhere(function ($q) use ($dateStartTime, $dateEndTime): void {
                                $q->where('start_time', '<=', $dateStartTime)
                                  ->where('end_time', '>=', $dateEndTime);
                            });
                    })
                    ->lockForUpdate()
                    ->exists();

                if ($overlapping) {
                    throw new \App\Exceptions\BookingConflictException(
                        "The selected time slot on {$dateStr} overlaps with an existing booking."
                    );
                }

                $error = $this->bookingService->validateAvailabilityForSitter(
                    $sitter->id,
                    $date->toDateString(),
                    $dateStartTime,
                    $dateEndTime,
                    childrenCount: $childrenCount,
                );
                if ($error) {
                    throw new \App\Exceptions\BookingConflictException(
                        "{$dateStr}: {$error}"
                    );
                }

                $pricing = $this->bookingService->calculateTotal(
                    $sitter->babysitterProfile,
                    $duration,
                    $childrenCount,
                    $specialNeedsCount,
                );

                $booking = Booking::create([
                    'booking_group_id' => $bookingGroupId,
                    'customer_id' => $request->user()->id,
                    'sitter_id' => $sitter->id,
                    'date' => $date->toDateString(),
                    'start_time' => $dateStartTime,
                    'end_time' => $dateEndTime,
                    'duration' => $duration,
                    'total_amount' => $pricing['total'],
                    'base_amount' => $pricing['base'],
                    'extra_amount' => $pricing['extra'],
                    'special_needs_amount' => $pricing['special'],
                    'status' => 'pending',
                    'address' => $request->input('address'),
                    'children_count' => $childrenCount,
                    'special_needs_count' => $specialNeedsCount,
                    'children_ages' => $request->input('children_ages', []),
                    'children_names' => $request->input('children_names', []),
                    'notes' => $request->input('notes'),
                    'special_instructions' => $request->input('special_instructions'),
                    'schedule_events' => $request->input('schedule_events', []),
                    'status_history' => [[
                        'from' => null,
                        'to' => 'pending',
                        'timestamp' => now()->toISOString(),
                        'reason' => 'Multi-day booking created',
                    ]],
                ]);

                $booking->update(['confirmation_deadline' => now()->addMinutes(30)]);

                $bookedDates[] = $dateStr;
            }

            $bookings = Booking::query()
                ->where('booking_group_id', $bookingGroupId)
                ->with(['customer', 'sitter.babysitterProfile'])
                ->get()
                ->all();

            $this->bookingGroupService->createFromBookings($bookings, $bookingGroupId, $request->user(), $sitter);

            return $bookings;
        });

        $this->bookingGroupService->notifyGroupChange(
            BookingGroup::find($bookingGroupId),
            'created',
        );

        $count = count($bookings);

        return $this->created([
            'bookingGroupId' => $bookingGroupId,
            'bookings' => BookingResource::collection(collect($bookings))->resolve(request()),
        ], "{$count} bookings created successfully");
    }

    public function update(UpdateBookingRequest $request, Booking $booking): JsonResponse
    {
        $this->authorize('update', $booking);

        if (!in_array($booking->status, ['pending', 'confirmed'])) {
            return $this->error($this->editStatusErrorMessage($booking->status), 422);
        }

        $isGroupSession = $booking->booking_group_id !== null;

        if ($isGroupSession) {
            return $this->updateGroup($request, $booking);
        }

        $data = $request->validated();

        $newDate = $data['date'] ?? $booking->date->toDateString();
        $newStartTime = $data['start_time'] ?? $booking->start_time;
        $newEndTime = $data['end_time'] ?? $booking->end_time;

        if ($newDate === now()->toDateString() && $newStartTime < now()->format('H:i')) {
            return $this->error('The selected start time has already passed. Please choose a future time.', 422);
        }

        $sitter = $booking->sitter->load('babysitterProfile');
        $effectiveDuration = (int) ($data['duration'] ?? $booking->duration);
        $effectiveChildrenCount = (int) ($data['children_count'] ?? $booking->children_count ?? 1);
        $effectiveSpecialNeedsCount = (int) ($data['special_needs_count'] ?? $booking->special_needs_count ?? 0);

        $error = $this->bookingService->validateAvailability($booking, $newDate, $newStartTime, $newEndTime, $effectiveChildrenCount);
        if ($error) {
            return $this->error($error, 422);
        }

        if ($data['duration'] ?? $data['children_count'] ?? $data['special_needs_count'] ?? null) {
            $pricing = $this->bookingService->calculateTotal(
                $sitter->babysitterProfile,
                $effectiveDuration,
                $effectiveChildrenCount,
                $effectiveSpecialNeedsCount,
            );
            $data['total_amount'] = $pricing['total'];
            $data['base_amount'] = $pricing['base'];
            $data['extra_amount'] = $pricing['extra'];
            $data['special_needs_amount'] = $pricing['special'];
        }

        if ($booking->status === 'confirmed') {
            $newStatus = 'pending';
            $data['status'] = 'pending';
            $data['confirmed_at'] = null;
        } else {
            $newStatus = null;
        }

        $booking->update($data);

        if ($newStatus) {
            $booking->update(['confirmation_deadline' => now()->addMinutes(30)]);
            $this->bookingService->transitionStatus($booking, $newStatus, $request->user(), 'Booking edited by customer');
        }

        return $this->success(
            BookingResource::make($booking->fresh()->load(['customer', 'sitter.babysitterProfile'])),
            $newStatus
                ? 'Booking updated. Your changes require provider review.'
                : 'Booking updated successfully',
        );
    }

    private function updateGroup(Request $request, Booking $booking): JsonResponse
    {
        $groupId = $booking->booking_group_id;

        $groupBookings = Booking::query()
            ->where('booking_group_id', $groupId)
            ->whereIn('status', ['pending', 'confirmed'])
            ->get();

        $data = $request->validated();
        $sitter = $booking->sitter->load('babysitterProfile');

        $effectiveDuration = (int) ($data['duration'] ?? $booking->duration);
        $effectiveChildrenCount = (int) ($data['children_count'] ?? $booking->children_count ?? 1);
        $effectiveSpecialNeedsCount = (int) ($data['special_needs_count'] ?? $booking->special_needs_count ?? 0);

        if ($data['duration'] ?? $data['children_count'] ?? $data['special_needs_count'] ?? null) {
            $pricing = $this->bookingService->calculateTotal(
                $sitter->babysitterProfile,
                $effectiveDuration,
                $effectiveChildrenCount,
                $effectiveSpecialNeedsCount,
            );
            $data['total_amount'] = $pricing['total'];
            $data['base_amount'] = $pricing['base'];
            $data['extra_amount'] = $pricing['extra'];
            $data['special_needs_amount'] = $pricing['special'];
        }

        $wasConfirmed = $booking->status === 'confirmed';
        $anyNewStatus = null;

        try {
            DB::transaction(function () use ($groupBookings, $data, $wasConfirmed, $request, &$anyNewStatus): void {
                foreach ($groupBookings as $groupBooking) {
                    $updateData = $data;

                    if ($wasConfirmed && in_array($groupBooking->status, ['pending', 'confirmed'])) {
                        $updateData['status'] = 'pending';
                        $updateData['confirmed_at'] = null;
                        $anyNewStatus = 'pending';
                    }

                    unset($updateData['date']);

                    $groupBooking->update($updateData);
                }
            });
        } catch (\Throwable $e) {
            Log::error('Group update failed', [
                'booking_group_id' => $groupId,
                'user_id' => $request->user()->id,
                'error' => $e->getMessage(),
            ]);
            return $this->error('Failed to update booking group. Please try again.', 500);
        }

        if ($anyNewStatus) {
            $this->bookingService->transitionStatus($booking, $anyNewStatus, $request->user(), 'Group booking edited by customer');
            $this->bookingGroupService->onBookingStatusChange($booking);
        }

        $updated = Booking::query()
            ->where('booking_group_id', $groupId)
            ->with(['customer', 'sitter.babysitterProfile'])
            ->get();

        return $this->success([
            'bookingGroupId' => $groupId,
            'bookings' => BookingResource::collection($updated)->resolve(request()),
        ], $wasConfirmed
            ? 'Booking group updated. Your changes require provider review.'
            : 'Booking group updated successfully');
    }

    public function cancel(CancelBookingRequest $request, Booking $booking): JsonResponse
    {
        $this->authorize('update', $booking);

        try {
            return DB::transaction(function () use ($booking, $request): JsonResponse {
                $booking = Booking::lockForUpdate()->findOrFail($booking->id);

                if (!in_array($booking->status, ['pending', 'confirmed'])) {
                    return $this->error($this->cancelStatusErrorMessage($booking->status), 422);
                }

                $isGroupSession = $booking->booking_group_id !== null;

                $this->bookingService->transitionStatus(
                    $booking,
                    'cancelled',
                    $request->user(),
                    $request->input('reason'),
                    $isGroupSession,
                );

                if ($isGroupSession) {
                    $this->bookingGroupService->handleCancellation($booking, $request->user(), $request->input('reason'));
                }

                return $this->success(
                    BookingResource::make($booking->fresh()->load([
                        'customer', 'sitter.babysitterProfile', 'timelineEvents',
                    ])),
                    'Booking cancelled successfully',
                );
            });
        } catch (\Throwable $e) {
            Log::error('Booking cancel failed', [
                'booking_id' => $booking->id,
                'user_id' => $request->user()->id,
                'error' => $e->getMessage(),
            ]);
            return $this->error('Failed to cancel booking. Please try again.', 500);
        }
    }

    public function sitterCancel(Request $request, Booking $booking): JsonResponse
    {
        $this->authorize('update', $booking);

        try {
            return DB::transaction(function () use ($booking, $request): JsonResponse {
                $booking = Booking::lockForUpdate()->findOrFail($booking->id);

                if ($booking->sitter_id !== $request->user()->id) {
                    return $this->error('Only the assigned sitter can cancel this booking.', 403);
                }

                if ($booking->status !== 'confirmed') {
                    $hint = match ($booking->status) {
                        'pending' => 'This booking is still pending. You can decline it instead.',
                        'completed' => 'This booking has already been completed.',
                        'cancelled' => 'This booking has already been cancelled.',
                        'rejected' => 'This booking was already declined.',
                        'expired' => 'This booking has expired.',
                        'in_progress' => 'This booking is in progress. Use emergency cancel if needed.',
                        default => null,
                    };
                    return $this->error($hint ?? "Only confirmed bookings can be cancelled by the sitter. Current status: {$booking->status}.", 422);
                }

                if ($booking->sitter?->is_suspended) {
                    return $this->error('Your account is suspended. You cannot cancel bookings.', 403);
                }

                $request->validate(['reason' => ['required', 'string', 'min:10', 'max:500']]);

                $isGroupSession = $booking->booking_group_id !== null;

                $this->bookingService->transitionStatus(
                    $booking,
                    'cancelled',
                    $request->user(),
                    $request->input('reason'),
                    $isGroupSession,
                );

                if ($isGroupSession) {
                    $this->bookingGroupService->handleCancellation($booking, $request->user(), $request->input('reason'));
                }

                return $this->success(
                    BookingResource::make($booking->fresh()->load([
                        'customer', 'sitter.babysitterProfile', 'timelineEvents',
                    ])),
                    'Booking cancelled by sitter',
                );
            });
        } catch (\Throwable $e) {
            Log::error('Sitter cancel failed', [
                'booking_id' => $booking->id,
                'user_id' => $request->user()->id,
                'error' => $e->getMessage(),
            ]);
            return $this->error('Failed to cancel booking. Please try again.', 500);
        }
    }

    public function timeline(Booking $booking): JsonResponse
    {
        $this->authorize('view', $booking);

        $events = $booking->timelineEvents()
            ->latest()
            ->with('actor:id,name')
            ->get();

        return $this->success(
            TimelineEventResource::collection($events),
            'Timeline retrieved successfully',
        );
    }

    public function confirm(Request $request, Booking $booking): JsonResponse
    {
        $this->authorize('confirm', $booking);

        try {
            return DB::transaction(function () use ($booking, $request): JsonResponse {
                $booking = Booking::lockForUpdate()->findOrFail($booking->id);

                if ($booking->status !== 'pending') {
                    $hint = match ($booking->status) {
                        'confirmed' => 'This booking has already been confirmed.',
                        'completed' => 'This booking has already been completed.',
                        'cancelled' => 'This booking has been cancelled and cannot be confirmed.',
                        'rejected' => 'This booking was already declined.',
                        'expired' => 'This booking has expired.',
                        'in_progress' => 'This booking is already in progress.',
                        default => null,
                    };
                    return $this->error($hint ?? "Only pending bookings can be confirmed. Current status: {$booking->status}.", 422);
                }

                if ($booking->booking_group_id) {
                    return $this->confirmGroup($request, $booking);
                }

                return $this->confirmSingle($request, $booking);
            });
        } catch (\Throwable $e) {
            Log::error('Booking confirm failed', [
                'booking_id' => $booking->id,
                'user_id' => $request->user()->id,
                'error' => $e->getMessage(),
            ]);
            return $this->error('Failed to confirm booking. Please try again.', 500);
        }
    }

    private function confirmSingle(Request $request, Booking $booking): JsonResponse
    {
        $isExpired = $booking->date->isPast()
            || ($booking->end_time && $booking->end_time <= now()->format('H:i:s') && $booking->date->isToday());

        if ($isExpired) {
            $this->bookingService->transitionStatus($booking, 'cancelled', $request->user(), 'Booking date has passed — no response from the sitter.');
            return $this->error('This booking has been cancelled because its date has passed.', 422);
        }

        if ($booking->sitter?->is_suspended) {
            return $this->error('Your account is suspended. You cannot confirm bookings.', 403);
        }

        $error = $this->bookingService->validateAvailabilityForSitter(
            $booking->sitter_id,
            $booking->date->toDateString(),
            $booking->start_time,
            $booking->end_time,
            $booking->id,
            childrenCount: $booking->children_count ?? 1,
        );
        if ($error) {
            return $this->error($error, 422);
        }

        $this->bookingService->transitionStatus($booking, 'confirmed', $request->user(), null, false);

        if ($booking->session_status === 'pending') {
            $booking->qr_start_token = hash('sha256', Str::random(64) . ':' . $booking->id . ':' . time());
            $booking->session_status = 'start_qr_generated';
            $booking->save();
        }

        return $this->success(
            BookingResource::make($booking->fresh()->load(['customer', 'sitter.babysitterProfile'])),
            'Booking confirmed successfully',
        );
    }

    private function confirmGroup(Request $request, Booking $booking): JsonResponse
    {
        $user = $request->user();

        if ($booking->sitter?->is_suspended) {
            return $this->error('Your account is suspended. You cannot confirm bookings.', 403);
        }

        $siblings = Booking::lockForUpdate()
            ->where('booking_group_id', $booking->booking_group_id)
            ->where('status', 'pending')
            ->get();

        if ($siblings->isEmpty()) {
            return $this->error('No pending sessions found in this group.', 422);
        }

        $confirmed = 0;
        $cancelled = 0;

        foreach ($siblings as $sibling) {
            $isExpired = $sibling->date->isPast()
                || ($sibling->end_time && $sibling->end_time <= now()->format('H:i:s') && $sibling->date->isToday());

            if ($isExpired) {
                $this->bookingService->transitionStatus(
                    $sibling, 'cancelled', $user,
                    'Booking date has passed — auto-cancelled during group confirmation.', true,
                );
                $cancelled++;
                continue;
            }

            $conflict = $this->bookingService->validateAvailabilityForSitter(
                $sibling->sitter_id,
                $sibling->date->toDateString(),
                $sibling->start_time,
                $sibling->end_time,
                $sibling->id,
                childrenCount: $sibling->children_count ?? 1,
            );
            if ($conflict) {
                $this->bookingService->transitionStatus(
                    $sibling, 'cancelled', $user,
                    "Sitter availability conflict: {$conflict}", true,
                );
                $cancelled++;
                continue;
            }

            $this->bookingService->transitionStatus($sibling, 'confirmed', $user, null, true);

            if ($sibling->session_status === 'pending') {
                $sibling->qr_start_token = hash('sha256', Str::random(64) . ':' . $sibling->id . ':' . time());
                $sibling->session_status = 'start_qr_generated';
                $sibling->save();
            }
            $confirmed++;
        }

        if ($confirmed === 0) {
            $booking->refresh();
            $this->bookingGroupService->onBookingStatusChange($booking);
            return $this->error('All sessions in this group have passed their time and cannot be confirmed.', 422);
        }

        $booking->refresh();
        $this->bookingGroupService->onBookingStatusChange($booking);

        if ($cancelled > 0) {
            $this->bookingGroupService->handleCancellation($booking, $user);
        } else {
            $group = BookingGroup::find($booking->booking_group_id);
            if ($group) {
                $this->bookingGroupService->notifyGroupChange($group, 'confirmed', $user);
            }
        }

        $message = "{$confirmed} session(s) confirmed successfully.";
        if ($cancelled > 0) {
            $message .= " {$cancelled} session(s) were past their date and have been cancelled.";
        }

        return $this->success(
            BookingResource::make($booking->fresh()->load(['customer', 'sitter.babysitterProfile'])),
            $message,
        );
    }

    public function reject(Request $request, Booking $booking): JsonResponse
    {
        $this->authorize('confirm', $booking);

        try {
            return DB::transaction(function () use ($booking, $request): JsonResponse {
                $booking = Booking::lockForUpdate()->findOrFail($booking->id);

                if ($booking->status !== 'pending') {
                    $hint = match ($booking->status) {
                        'confirmed' => 'This booking has already been confirmed and cannot be declined.',
                        'completed' => 'This booking has been completed.',
                        'cancelled' => 'This booking has already been cancelled.',
                        'rejected' => 'This booking was already declined.',
                        'expired' => 'This booking has expired.',
                        'in_progress' => 'This booking is in progress.',
                        default => null,
                    };
                    return $this->error($hint ?? "Only pending bookings can be declined. Current status: {$booking->status}.", 422);
                }

                if ($booking->date->isPast() || ($booking->end_time && $booking->end_time <= now()->format('H:i:s') && $booking->date->isToday())) {
                    $this->bookingService->transitionStatus($booking, 'cancelled', $request->user(), 'Booking date has passed — no response from the sitter.');
                    return $this->error('This booking has been cancelled because its date has passed.', 422);
                }

                if ($booking->sitter?->is_suspended) {
                    return $this->error('Your account is suspended. You cannot reject bookings.', 403);
                }

                $request->validate(['reason' => ['required', 'string', 'min:3', 'max:500']]);

                $isGroupSession = $booking->booking_group_id !== null;

                $this->bookingService->transitionStatus($booking, 'rejected', $request->user(), $request->input('reason'), $isGroupSession);

                if ($isGroupSession) {
                    $this->bookingGroupService->handleCancellation($booking, $request->user(), $request->input('reason'));
                }

                return $this->success(
                    BookingResource::make($booking->fresh()->load(['customer', 'sitter.babysitterProfile'])),
                    'Booking rejected',
                );
            });
        } catch (\Throwable $e) {
            Log::error('Booking reject failed', [
                'booking_id' => $booking->id,
                'user_id' => $request->user()->id,
                'error' => $e->getMessage(),
            ]);
            return $this->error('Failed to reject booking. Please try again.', 500);
        }
    }

    public function complete(Request $request, Booking $booking): JsonResponse
    {
        $this->authorize('update', $booking);

        try {
            return DB::transaction(function () use ($booking, $request): JsonResponse {
                $booking = Booking::lockForUpdate()->findOrFail($booking->id);

                if ($booking->status !== 'confirmed' && $booking->status !== 'in_progress') {
                    $hint = match ($booking->status) {
                        'pending' => 'This booking has not been confirmed yet. Please wait for the sitter to accept.',
                        'completed' => 'This booking has already been marked as completed.',
                        'cancelled' => 'This booking was cancelled.',
                        'rejected' => 'This booking was declined.',
                        'expired' => 'This booking has expired.',
                        default => null,
                    };
                    return $this->error($hint ?? "Only confirmed or in-progress bookings can be completed. Current status: {$booking->status}.", 422);
                }

                if ($booking->sitter?->is_suspended) {
                    return $this->error('Your account is suspended. You cannot complete bookings.', 403);
                }

                $isGroupSession = $booking->booking_group_id !== null;

                if ($isGroupSession) {
                    // For group bookings: mark day as completed but keep booking in_progress
                    // until all days in the group are done
                    $booking->update([
                        'session_status' => 'completed',
                        'is_day_completed' => true,
                        'day_completed_at' => now(),
                        'session_ended_at' => now(),
                        'gps_ended_at' => now(),
                        'qr_end_token' => null,
                    ]);

                    if ($booking->sitter && $booking->sitter->babysitterProfile) {
                        $booking->sitter->babysitterProfile->increment('total_earnings', (int) $booking->total_amount);
                    }

                    $this->bookingGroupService->handleDayCompletion($booking);

                    return $this->success(
                        BookingResource::make($booking->fresh()->load(['customer', 'sitter.babysitterProfile'])),
                        'Day completed successfully',
                    );
                }

                $this->bookingService->transitionStatus($booking, 'completed', $request->user());

                return $this->success(
                    BookingResource::make($booking->fresh()->load(['customer', 'sitter.babysitterProfile'])),
                    'Booking completed successfully',
                );
            });
        } catch (\Throwable $e) {
            Log::error('Booking complete failed', [
                'booking_id' => $booking->id,
                'user_id' => $request->user()->id,
                'error' => $e->getMessage(),
            ]);
            return $this->error('Failed to complete session. Please try again.', 500);
        }
    }

    public function review(StoreBookingReviewRequest $request, Booking $booking): JsonResponse
    {
        $this->authorize('view', $booking);

        if ($booking->booking_group_id) {
            return $this->error('This booking is part of a multi-day group. Please submit your review for the entire group.', 422);
        }

        if ($booking->status !== 'completed') {
            $hint = match ($booking->status) {
                'pending' => 'This booking has not been completed yet. You can leave a review after the booking is finished.',
                'confirmed' => 'This booking has not started yet. Reviews can only be submitted after the booking is completed.',
                'cancelled' => 'This booking was cancelled. Reviews can only be submitted for completed bookings.',
                'rejected' => 'This booking was declined.',
                'expired' => 'This booking has expired.',
                'in_progress' => 'The booking is still in progress. Please wait until it is completed to leave a review.',
                default => null,
            };
            return $this->error($hint ?? "Only completed bookings can be reviewed. Current status: {$booking->status}.", 422);
        }

        if ($booking->customer_id !== $request->user()->id) {
            return $this->error('Only the customer who made the booking can leave a review.', 403);
        }

        $isUpdate = $booking->rating !== null;
        $rating = (float) $request->input('rating');
        $rawReview = $request->input('review');
        $reviewText = $rawReview !== null ? strip_tags(htmlspecialchars($rawReview, ENT_QUOTES, 'UTF-8')) : null;

        DB::transaction(function () use ($booking, $rating, $reviewText, $isUpdate): void {
            $booking->update([
                'rating' => $rating,
                'review' => $reviewText,
            ]);

            $history = (array) ($booking->status_history ?? []);
            $history[] = [
                'from' => $booking->status,
                'to' => $booking->status,
                'timestamp' => now()->toISOString(),
                'reason' => $isUpdate
                    ? 'Review updated to ' . $rating . ' stars'
                    : 'Review submitted with ' . $rating . ' stars',
            ];
            $booking->updateQuietly(['status_history' => $history]);

            $profile = BabysitterProfile::firstWhere('user_id', $booking->sitter_id);
            if ($profile) {
                $stats = Booking::query()
                    ->where('sitter_id', $booking->sitter_id)
                    ->where('status', 'completed')
                    ->whereNotNull('rating')
                    ->selectRaw('AVG(rating) as avg_rating, COUNT(*) as review_count')
                    ->first();
                $profile->updateQuietly([
                    'rating' => round((float) ($stats?->avg_rating ?? 0), 2),
                    'review_count' => (int) ($stats?->review_count ?? 0),
                ]);
            }

            $this->timelineService->recordReview($booking);
        });

        $notifKey = $isUpdate ? 'review_updated_title' : 'review_received_title';
        $notifBody = $isUpdate ? 'review_updated_body' : 'review_received_body';
        $booking->sitter->notify(new BookingNotification(
            $notifKey,
            $notifBody,
            [
                '{customer_name}' => $booking->customer->name,
                '{rating}' => (string) $rating,
                '{booking_id}' => (string) $booking->id,
            ],
            $booking,
            'review',
        ));

        $message = $isUpdate ? 'Review updated successfully' : 'Review submitted successfully';
        return $this->success(
            BookingResource::make($booking->fresh()->load(['customer', 'sitter.babysitterProfile'])),
            $message,
        );
    }

    public function start(Request $request, Booking $booking): JsonResponse
    {
        $this->authorize('start', $booking);

        try {
            return DB::transaction(function () use ($booking, $request): JsonResponse {
                $booking = Booking::lockForUpdate()->findOrFail($booking->id);

                if ($booking->status !== 'confirmed') {
                    $hint = match ($booking->status) {
                        'pending' => 'This booking has not been confirmed yet. Please confirm it first.',
                        'completed' => 'This booking has already been completed.',
                        'cancelled' => 'This booking was cancelled.',
                        'rejected' => 'This booking was declined.',
                        'expired' => 'This booking has expired.',
                        'in_progress' => 'This booking has already been started.',
                        default => null,
                    };
                    return $this->error($hint ?? "Only confirmed bookings can be started. Current status: {$booking->status}.", 422);
                }

                if ($booking->sitter?->is_suspended) {
                    return $this->error('Your account is suspended. You cannot start bookings.', 403);
                }

                $isExpired = $booking->date->isPast()
                    || ($booking->end_time && $booking->end_time <= now()->format('H:i:s') && $booking->date->isToday());

                if ($isExpired) {
                    $this->bookingService->transitionStatus(
                        $booking, 'cancelled', $request->user(),
                        'Booking date has passed — auto-cancelled before session start.',
                        $booking->booking_group_id !== null,
                    );

                    if ($booking->booking_group_id) {
                        $this->bookingGroupService->handleCancellation($booking, $request->user());

                        $nextBooking = Booking::where('booking_group_id', $booking->booking_group_id)
                            ->where('id', '!=', $booking->id)
                            ->where('status', 'confirmed')
                            ->whereDate('date', '>=', now()->toDateString())
                            ->orderBy('date')
                            ->first();

                        if ($nextBooking) {
                            return $this->start($request, $nextBooking);
                        }

                        return $this->error('This session has expired. No future sessions available in this group.', 422);
                    }

                    return $this->error('This booking has been cancelled because its date has passed.', 422);
                }

                $this->bookingService->transitionStatus($booking, 'in_progress', $request->user(), null, $booking->booking_group_id !== null);

                if ($booking->booking_group_id) {
                    $this->bookingGroupService->onBookingStatusChange($booking);
                }

                return $this->success(
                    BookingResource::make($booking->fresh()->load(['customer', 'sitter.babysitterProfile'])),
                    'Booking started successfully',
                );
            });
        } catch (\Throwable $e) {
            Log::error('Booking start failed', [
                'booking_id' => $booking->id,
                'user_id' => $request->user()->id,
                'error' => $e->getMessage(),
            ]);
            return $this->error('Failed to start session. Please try again.', 500);
        }
    }

    public function rebook(Request $request, Booking $booking): JsonResponse
    {
        if ($request->user()->id !== $booking->customer_id) {
            return $this->error('Only the customer can rebook a booking.', 403);
        }

        if (!in_array($booking->status, ['completed', 'cancelled'])) {
            $hint = match ($booking->status) {
                'pending' => 'This booking is still pending.',
                'confirmed' => 'This booking is confirmed.',
                'rejected' => 'This booking was declined.',
                'expired' => 'This booking has expired.',
                'in_progress' => 'This booking is in progress.',
                default => null,
            };
            return $this->error(
                $hint ?? "This booking cannot be rebooked in its current state.",
                422,
            );
        }

        $isGroupSession = $booking->booking_group_id !== null;

        if (!$isGroupSession) {
            $request->validate([
                'date' => ['required', 'date', 'after_or_equal:today'],
                'start_time' => ['required', 'date_format:H:i'],
                'end_time' => ['required', 'date_format:H:i', 'after:start_time'],
                'duration' => ['required', 'integer', 'min:1', 'max:24'],
                'children_count' => ['nullable', 'integer', 'min:1', 'max:12'],
                'special_needs_count' => ['nullable', 'integer', 'min:0', 'max:10'],
                'children_ages' => ['nullable', 'array', 'max:10'],
                'children_ages.*' => ['string', 'max:20'],
                'notes' => ['nullable', 'string', 'max:1000'],
                'special_instructions' => ['nullable', 'string', 'max:1000'],
                'address' => ['nullable', 'string', 'max:255'],
            ]);
        }

        return DB::transaction(function () use ($booking, $request, $isGroupSession): JsonResponse {
            $booking = Booking::lockForUpdate()->findOrFail($booking->id);

            $sitter = $booking->sitter->load('babysitterProfile');

            if (!$sitter->babysitterProfile?->is_available) {
                throw new \App\Exceptions\BookingConflictException('This babysitter is currently unavailable.');
            }

            if ($sitter->is_suspended) {
                throw new \App\Exceptions\BookingConflictException('This babysitter is currently unavailable.');
            }

            if ($isGroupSession) {
                $groupId = $booking->booking_group_id;
                $groupBookings = Booking::query()
                    ->where('booking_group_id', $groupId)
                    ->whereIn('status', ['cancelled', 'rejected'])
                    ->lockForUpdate()
                    ->get();

                $pricing = null;

                if ($request->hasAny(['duration', 'children_count', 'special_needs_count'])) {
                    $duration = (int) $request->input('duration', $booking->duration);
                    $childrenCount = (int) ($request->input('children_count', $booking->children_count ?? 1));
                    $specialNeedsCount = (int) ($request->input('special_needs_count', $booking->special_needs_count ?? 0));

                    $pricing = $this->bookingService->calculateTotal(
                        $sitter->babysitterProfile,
                        $duration,
                        $childrenCount,
                        $specialNeedsCount,
                    );
                }

                foreach ($groupBookings as $gb) {
                    $updateData = [
                        'cancelled_at' => null,
                        'cancellation_reason' => null,
                        'rejected_at' => null,
                        'rejection_reason' => null,
                        'confirmation_deadline' => now()->addMinutes(30),
                    ];

                    if ($pricing) {
                        $updateData['total_amount'] = $pricing['total'];
                        $updateData['base_amount'] = $pricing['base'];
                        $updateData['extra_amount'] = $pricing['extra'];
                        $updateData['special_needs_amount'] = $pricing['special'];
                        $updateData['children_count'] = $request->input('children_count', $gb->children_count);
                        $updateData['special_needs_count'] = $request->input('special_needs_count', $gb->special_needs_count ?? 0);
                        $updateData['children_ages'] = $request->input('children_ages', $gb->children_ages);
                        $updateData['children_names'] = $request->input('children_names', $gb->children_names);
                        $updateData['duration'] = $request->input('duration', $gb->duration);
                    }

                    if ($request->has('notes')) $updateData['notes'] = $request->input('notes');
                    if ($request->has('address')) $updateData['address'] = $request->input('address');
                    if ($request->has('special_instructions')) $updateData['special_instructions'] = $request->input('special_instructions');

                    if ($gb->id === $booking->id && $request->has('date')) {
                        $updateData['date'] = $request->date('date')->toDateString();
                        $updateData['start_time'] = $request->input('start_time');
                        $updateData['end_time'] = $request->input('end_time');
                    }

                    $oldStatus = $gb->status;
                    $gb->updateQuietly($updateData);
                    $this->bookingService->transitionStatus($gb, 'pending', $request->user(),
                        reason: 'Rebooked by customer'
                    );

                    $this->timelineService->recordStatusChange(
                        $gb, $oldStatus, 'pending',
                        actorId: $request->user()->id, reason: 'Rebooked by customer'
                    );
                }

                $this->bookingGroupService->onBookingStatusChange($booking);

                $bookingGroupModel = \App\Models\BookingGroup::where('id', $groupId)->first();
                if ($bookingGroupModel) {
                    $this->bookingGroupService->syncFromGroup($bookingGroupModel);
                }

                return $this->success(
                    BookingResource::make($booking->fresh()->load(['customer', 'sitter.babysitterProfile'])),
                    'Multi-day booking rebooked successfully',
                );
            }

            $requestedDate = $request->date('date');
            $duration = (int) $request->integer('duration');
            $childrenCount = (int) ($request->input('children_count', $booking->children_count ?? 1));
            $specialNeedsCount = (int) ($request->input('special_needs_count', $booking->special_needs_count ?? 0));

            $error = $this->bookingService->validateAvailabilityForSitter(
                $sitter->id,
                $requestedDate->toDateString(),
                $request->input('start_time'),
                $request->input('end_time'),
                childrenCount: $childrenCount,
            );
            if ($error) {
                throw new \App\Exceptions\BookingConflictException($error);
            }

            $pricing = $this->bookingService->calculateTotal(
                $sitter->babysitterProfile,
                $duration,
                $childrenCount,
                $specialNeedsCount,
            );

            $this->bookingService->transitionStatus($booking, 'pending', $request->user(),
                reason: 'Rebooked by customer'
            );

            $booking->updateQuietly([
                'date' => $requestedDate->toDateString(),
                'start_time' => $request->input('start_time'),
                'end_time' => $request->input('end_time'),
                'duration' => $duration,
                'total_amount' => $pricing['total'],
                'base_amount' => $pricing['base'],
                'extra_amount' => $pricing['extra'],
                'special_needs_amount' => $pricing['special'],
                'address' => $request->input('address', $booking->address),
                'children_count' => $childrenCount,
                'special_needs_count' => $specialNeedsCount,
                'children_ages' => $request->input('children_ages', $booking->children_ages),
                'children_names' => $request->input('children_names', $booking->children_names),
                'notes' => $request->input('notes', $booking->notes),
                'special_instructions' => $request->input('special_instructions', $booking->special_instructions),
                'confirmation_deadline' => now()->addMinutes(30),
                'cancelled_at' => null,
                'cancellation_reason' => null,
                'rejected_at' => null,
                'rejection_reason' => null,
            ]);

            $this->timelineService->recordStatusChange(
                $booking, 'cancelled', 'pending',
                actorId: $request->user()->id, reason: 'Rebooked by customer'
            );

            return $this->success(
                BookingResource::make($booking->fresh()->load(['customer', 'sitter.babysitterProfile'])),
                'Booking rebooked successfully',
            );
        });
    }

    public function groupCancel(Request $request): JsonResponse
    {
        $request->validate([
            'booking_group_id' => ['required', 'string', 'size:36'],
            'date_ids' => ['nullable', 'array', 'max:365'],
            'date_ids.*' => ['integer', 'exists:bookings,id'],
        ]);

        $bookingGroupId = $request->input('booking_group_id');
        $dateIds = $request->input('date_ids');

        try {
            return DB::transaction(function () use ($bookingGroupId, $dateIds, $request): JsonResponse {
                $query = Booking::query()
                    ->where('booking_group_id', $bookingGroupId)
                    ->whereIn('status', ['pending', 'confirmed']);

                if ($dateIds) {
                    $query->whereIn('id', $dateIds);
                }

                $bookings = $query->lockForUpdate()->get();

                if ($bookings->isEmpty()) {
                    return $this->error('No cancellable bookings found in this group.', 404);
                }

                $authorizedBookings = $bookings->filter(function ($booking) use ($request) {
                    return $request->user()->id === $booking->customer_id
                        || $request->user()->id === $booking->sitter_id;
                });

                if ($authorizedBookings->isEmpty()) {
                    return $this->error('You are not authorized to cancel these bookings.', 403);
                }

                $isFullCancel = $authorizedBookings->count() === $bookings->count();

                foreach ($authorizedBookings as $booking) {
                    $this->bookingService->transitionStatus(
                        $booking,
                        'cancelled',
                        $request->user(),
                        $request->input('reason', 'Cancelled by customer'),
                        isGroupSession: true,
                    );
                }

                if ($isFullCancel) {
                    $this->bookingGroupService->handleCancellation(
                        $authorizedBookings->first(),
                        $request->user(),
                        $request->input('reason'),
                    );
                } else {
                    $this->bookingGroupService->onBookingStatusChange($authorizedBookings->first());
                }

                $updated = Booking::query()
                    ->where('booking_group_id', $bookingGroupId)
                    ->with(['customer', 'sitter.babysitterProfile'])
                    ->get();

                $count = $authorizedBookings->count();
                $cancelledSome = $count < $bookings->count();

                $message = $cancelledSome
                    ? "{$count} booking(s) cancelled from the group"
                    : "All {$count} booking(s) cancelled successfully";

                return $this->success(
                    BookingResource::collection($updated),
                    $message,
                );
            });
        } catch (\Throwable $e) {
            Log::error('Group cancel failed', [
                'booking_group_id' => $bookingGroupId,
                'user_id' => $request->user()->id,
                'error' => $e->getMessage(),
            ]);
            return $this->error('Failed to cancel bookings. Please try again.', 500);
        }
    }

    public function groupShow(Request $request, string $bookingGroupId): JsonResponse
    {
        $bookings = Booking::query()
            ->where('booking_group_id', $bookingGroupId)
            ->with(['customer', 'sitter.babysitterProfile'])
            ->orderBy('date')
            ->get();

        if ($bookings->isEmpty()) {
            return $this->error('Booking group not found.', 404);
        }

        $first = $bookings->first();
        if ($request->user()->id !== $first->customer_id && $request->user()->id !== $first->sitter_id) {
            return $this->error('You are not authorized to view this booking group.', 403);
        }

        $bookingGroup = \App\Models\BookingGroup::where('id', $bookingGroupId)->first();

        $totalAmount = $bookings->sum('total_amount');
        $baseAmount = $bookings->sum('base_amount');
        $extraAmount = $bookings->sum('extra_amount');
        $specialNeedsAmount = $bookings->sum('special_needs_amount');
        $completedCount = $bookings->where(fn($b) => $b->status === 'completed' || $b->is_day_completed)->count();
        $cancelledCount = $bookings->whereIn('status', ['cancelled', 'rejected'])->count();

        return $this->success([
            'bookingGroupId' => $bookingGroupId,
            'bookings' => BookingResource::collection($bookings)->resolve(request()),
            'group' => $bookingGroup ? [
                'id' => $bookingGroup->id,
                'status' => $bookingGroup->status,
                'sessionCount' => $bookingGroup->session_count,
                'completedCount' => $bookingGroup->completed_count,
                'cancelledCount' => $bookingGroup->cancelled_count,
                'totalAmount' => (float) $bookingGroup->total_amount,
                'rating' => $bookingGroup->rating,
                'review' => $bookingGroup->review,
                'createdAt' => $bookingGroup->created_at?->toISOString(),
            ] : null,
            'summary' => [
                'total' => (float) $totalAmount,
                'base' => (float) $baseAmount,
                'extra' => (float) $extraAmount,
                'specialNeeds' => (float) $specialNeedsAmount,
                'count' => $bookings->count(),
                'completedCount' => $completedCount,
                'cancelledCount' => $cancelledCount,
                'dates' => $bookings->pluck('date')->map(fn($d) => $d->toDateString())->values(),
            ],
        ], 'Booking group retrieved successfully');
    }

    public function groupReview(StoreGroupReviewRequest $request, string $bookingGroupId): JsonResponse
    {
        $bookingGroup = BookingGroup::where('id', $bookingGroupId)->first();

        if (!$bookingGroup) {
            return $this->error('Booking group not found.', 404);
        }

        if ($request->user()->id !== $bookingGroup->customer_id) {
            return $this->error('Only the customer who made the booking can leave a review.', 403);
        }

        $incompleteCount = $bookingGroup->bookings()
            ->whereNotIn('status', ['completed', 'reviewed'])
            ->whereNotIn('status', ['cancelled', 'rejected', 'expired'])
            ->count();

        if ($incompleteCount > 0) {
            return $this->error('You can only review this group after all sessions are completed.', 422);
        }

        $isUpdate = $bookingGroup->rating !== null;
        $rating = (float) $request->input('rating');
        $rawReview = $request->input('review');
        $reviewText = $rawReview !== null ? strip_tags(htmlspecialchars($rawReview, ENT_QUOTES, 'UTF-8')) : null;

        DB::transaction(function () use ($bookingGroup, $rating, $reviewText): void {
            $bookingGroup->update([
                'rating' => $rating,
                'review' => $reviewText,
            ]);

            $profile = BabysitterProfile::firstWhere('user_id', $bookingGroup->sitter_id);
            if ($profile) {
                $stats = Booking::query()
                    ->where('sitter_id', $bookingGroup->sitter_id)
                    ->where('status', 'completed')
                    ->whereNotNull('rating')
                    ->selectRaw('AVG(rating) as avg_rating, COUNT(*) as review_count')
                    ->first();
                $profile->updateQuietly([
                    'rating' => round((float) ($stats?->avg_rating ?? 0), 2),
                    'review_count' => (int) ($stats?->review_count ?? 0),
                ]);
            }
        });

        $firstBooking = $bookingGroup->bookings()->first();
        if ($firstBooking) {
            $bookingGroup->sitter->notify(new BookingNotification(
                $isUpdate ? 'review_updated_title' : 'review_received_title',
                $isUpdate ? 'review_updated_body' : 'review_received_body',
                [
                    '{customer_name}' => $bookingGroup->customer->name,
                    '{rating}' => (string) $rating,
                    '{booking_id}' => (string) $firstBooking->id,
                ],
                $firstBooking,
                'review',
            ));
        }

        $message = $isUpdate ? 'Review updated successfully' : 'Review submitted successfully';
        return $this->success([
            'bookingGroupId' => $bookingGroup->id,
            'rating' => $rating,
            'review' => $reviewText,
        ], $message);
    }

    private function editStatusErrorMessage(string $status): string
    {
        return match ($status) {
            'cancelled' => 'This booking has been cancelled and cannot be edited. Please use "Rebook" to schedule a new booking with this sitter.',
            'completed' => 'This booking has been completed and cannot be edited. Please use "Rebook" to schedule a new booking with this sitter.',
            'rejected' => 'This booking was declined and cannot be edited. Please use "Edit & Submit Again" to create a new booking request.',
            'expired' => 'This booking has expired and cannot be edited. Please create a new booking.',
            'in_progress' => 'This booking is currently in progress and cannot be edited.',
            default => "This booking cannot be edited because its status is \"{$status}\". Only pending or confirmed bookings can be edited.",
        };
    }

    private function cancelStatusErrorMessage(string $status): string
    {
        return match ($status) {
            'completed' => 'This booking has already been completed and cannot be cancelled.',
            'cancelled' => 'This booking has already been cancelled.',
            'rejected' => 'This booking was already declined and cannot be cancelled.',
            'expired' => 'This booking has expired and cannot be cancelled.',
            'in_progress' => 'This booking is currently in progress and cannot be cancelled. Please contact the sitter or support for assistance.',
            default => "This booking cannot be cancelled because its status is \"{$status}\". Only pending or confirmed bookings can be cancelled.",
        };
    }

    public function sitterBookings(SitterBookingsRequest $request, User $sitter): JsonResponse
    {
        $this->authorize('viewSitterBookings', $sitter);

        $date = $request->input('date', now()->toDateString());
        $dateTo = $request->input('date_to', $date);

        $user = $request->user();
        $canViewCustomer = $user->id === $sitter->id || $user->role === 'admin';

        $selectFields = $canViewCustomer
            ? ['id', 'date', 'start_time', 'end_time', 'status', 'customer_id', 'sitter_id']
            : ['id', 'date', 'start_time', 'end_time', 'status', 'sitter_id'];

        $bookings = Booking::query()
            ->where('sitter_id', $sitter->id)
            ->whereBetween('date', [$date, $dateTo])
            ->whereIn('status', ['pending', 'confirmed', 'in_progress'])
            ->select($selectFields);

        if ($canViewCustomer) {
            $bookings->with(['customer:id,name']);
        }

        return $this->success(
            BookingResource::collection($bookings->paginate($request->integer('per_page', 20))),
            'Sitter bookings retrieved successfully',
        );
    }
}
