<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\UpdateSitterProfileRequest;
use App\Http\Resources\UserResource;
use App\Models\Booking;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;

class SitterProfileController extends Controller
{
    public function update(UpdateSitterProfileRequest $request): JsonResponse
    {
        $user = $request->user()->load('babysitterProfile');
        $profile = $user->babysitterProfile;

        if ($profile === null) {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.sitter_profile_not_found'),
            ], 404);
        }

        if ($user->is_suspended) {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.account_suspended_edit_profile'),
            ], 403);
        }

        $data = $request->safe()->collect()->toArray();

        $activeBookings = null;

        if (array_key_exists('included_children', $data) && (int) $data['included_children'] < (int) ($profile->included_children ?? 1)) {
            $activeBookings ??= $this->getActiveBookings($user->id);
            $newLimit = (int) $data['included_children'];
            $conflicting = $activeBookings->first(fn(Booking $b) => ($b->children_count ?? 1) > $newLimit);
            if ($conflicting) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Cannot reduce included children. You have an active booking with ' . ($conflicting->children_count ?? 1) . ' children on ' . Carbon::parse($conflicting->date)->format('M j, Y') . '.',
                ], 422);
            }
        }

        if (array_key_exists('absolute_max_children', $data) && $data['absolute_max_children'] !== null) {
            $newMax = (int) $data['absolute_max_children'];
            $currentMax = $profile->absolute_max_children;
            if ($currentMax === null || $newMax < $currentMax) {
                $activeBookings ??= $this->getActiveBookings($user->id);
                $conflicting = $activeBookings->first(fn(Booking $b) => ($b->children_count ?? 1) > $newMax);
                if ($conflicting) {
                    return response()->json([
                        'status' => 'error',
                        'message' => 'Cannot reduce max children limit. You have an active booking with ' . ($conflicting->children_count ?? 1) . ' children on ' . Carbon::parse($conflicting->date)->format('M j, Y') . '.',
                    ], 422);
                }
            }
        }

        if (array_key_exists('availability', $data)) {
            $newAvailability = $data['availability'];
            if (empty($newAvailability)) {
                $activeBookings ??= $this->getActiveBookings($user->id);
                if ($activeBookings->isNotEmpty()) {
                    return response()->json([
                        'status' => 'error',
                        'message' => __('messages.cannot_clear_availability_active_bookings'),
                    ], 422);
                }
            } else {
                $activeBookings ??= $this->getActiveBookings($user->id);

                $dayMap = [];
                foreach ($newAvailability as $slot) {
                    $dow = (int) ($slot['day_of_week'] ?? 0);
                    $dayMap[$dow] = $dayMap[$dow] ?? [];
                    $dayMap[$dow][] = [
                        'start' => $slot['start_time'] ?? '09:00',
                        'end' => $slot['end_time'] ?? '17:00',
                    ];
                }

                foreach ($activeBookings as $booking) {
                    $bookingDow = (int) Carbon::parse($booking->date)->format('w');
                    $slotsForDay = $dayMap[$bookingDow] ?? [];

                    if (empty($slotsForDay)) {
                        return response()->json([
                            'status' => 'error',
                            'message' => 'Cannot remove availability on ' . Carbon::parse($booking->date)->format('l') . '. You have an active booking on ' . Carbon::parse($booking->date)->format('M j, Y') . ' (' . substr((string) $booking->start_time, 0, 5) . ' - ' . substr((string) $booking->end_time, 0, 5) . ').',
                        ], 422);
                    }

                    $fitsInSlot = false;
                    foreach ($slotsForDay as $slot) {
                        $bookingStart = \Carbon\Carbon::parse($booking->start_time);
                        $bookingEnd = \Carbon\Carbon::parse($booking->end_time);
                        $slotStart = \Carbon\Carbon::parse($slot['start']);
                        $slotEnd = \Carbon\Carbon::parse($slot['end']);
                        if ($bookingStart->greaterThanOrEqualTo($slotStart) && $bookingEnd->lessThanOrEqualTo($slotEnd)) {
                            $fitsInSlot = true;
                            break;
                        }
                    }

                    if (!$fitsInSlot) {
                        return response()->json([
                            'status' => 'error',
                            'message' => 'New availability hours would conflict with an active booking on ' . Carbon::parse($booking->date)->format('M j, Y') . ' (' . substr((string) $booking->start_time, 0, 5) . ' - ' . substr((string) $booking->end_time, 0, 5) . '). Adjust the hours or handle the booking first.',
                        ], 422);
                    }
                }
            }
        }

        $profileFields = [
            'hourly_rate', 'included_children', 'extra_child_fee',
            'absolute_max_children', 'special_needs_rate', 'availability',
            'description', 'certificates', 'categories',
            'years_experience', 'bank_account', 'gallery_images',
        ];

        $profileData = array_intersect_key($data, array_flip($profileFields));
        if (!empty($profileData)) {
            $profile->update($profileData);
        }

        $userFields = ['bio', 'location', 'latitude', 'longitude'];
        $userData = array_intersect_key($data, array_flip($userFields));
        if (!empty($userData)) {
            if (isset($userData['bio'])) {
                $userData['bio'] = strip_tags($userData['bio']);
            }
            $user->update($userData);
        }

        return response()->json([
            'status' => 'success',
            'message' => __('messages.profile_updated'),
            'data' => new UserResource($user->fresh()->load('babysitterProfile')),
        ]);
    }

    private function getActiveBookings(int $sitterId)
    {
        return Booking::query()
            ->where('sitter_id', $sitterId)
            ->whereIn('status', ['pending', 'confirmed', 'in_progress'])
            ->whereDate('date', '>=', today())
            ->orderBy('date')
            ->get(['id', 'date', 'start_time', 'end_time', 'children_count']);
    }
}
