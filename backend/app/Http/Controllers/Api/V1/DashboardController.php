<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\BookingResource;
use App\Http\Resources\DashboardStatsResource;
use App\Http\Resources\UserResource;
use App\Models\Booking;
use App\Models\Favorite;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class DashboardController extends Controller
{
    public function stats(Request $request): JsonResponse
    {
        if ($request->user()->role !== 'babysitter') {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.only_sitters_access_dashboard'),
            ], 403);
        }

        $user = $request->user()->load([
            'babysitterProfile',
        ])->loadCount([
            'sitterBookings as total_bookings' => fn ($q) => $q->whereIn('status', ['pending', 'confirmed', 'completed', 'cancelled', 'in_progress']),
            'sitterBookings as completed_bookings' => fn ($q) => $q->where('status', 'completed'),
            'sitterBookings as cancelled_bookings' => fn ($q) => $q->where('status', 'cancelled'),
            'sitterBookings as pending_requests' => fn ($q) => $q->where('status', 'pending'),
            'sitterBookings as confirmed_count' => fn ($q) => $q->where('status', 'confirmed'),
        ]);

        $rejectedCount = Booking::query()
            ->where('sitter_id', $request->user()->id)
            ->where('status', 'rejected')
            ->count();

        $responseCount = Booking::query()
            ->where('sitter_id', $request->user()->id)
            ->whereIn('status', ['confirmed', 'rejected'])
            ->count();

        $acceptedCount = (int) ($user->confirmed_count ?? 0);
        $acceptanceRate = $responseCount > 0
            ? round(($acceptedCount / $responseCount) * 100, 1)
            : 0.0;

        $avgResponseTime = Booking::query()
            ->where('sitter_id', $request->user()->id)
            ->whereIn('status', ['confirmed', 'rejected'])
            ->whereNotNull('confirmed_at')
            ->selectRaw('AVG(TIMESTAMPDIFF(MINUTE, created_at, COALESCE(confirmed_at, rejected_at, created_at))) as avg_minutes')
            ->value('avg_minutes');

        $earningsAggregates = Booking::query()
            ->where('sitter_id', $request->user()->id)
            ->where('status', 'completed')
            ->selectRaw('
                COALESCE(SUM(base_amount), 0) as base_earnings,
                COALESCE(SUM(extra_amount), 0) as extra_earnings,
                COALESCE(SUM(special_needs_amount), 0) as special_needs_earnings
            ')
            ->first();

        return response()->json([
            'status' => 'success',
            'data' => array_merge(
                (new DashboardStatsResource($user, $earningsAggregates))->toArray($request),
                [
                    'confirmedCount' => $acceptedCount,
                    'rejectedCount' => (int) $rejectedCount,
                    'acceptanceRate' => $acceptanceRate,
                    'avgResponseTime' => $avgResponseTime ? round((float) $avgResponseTime, 0) : null,
                    'viewCount' => (int) ($user->babysitterProfile?->view_count ?? 0),
                    'followerCount' => (int) ($user->babysitterProfile?->follower_count ?? 0),
                ]
            ),
        ]);
    }

    public function recentRequests(Request $request): JsonResponse
    {
        if ($request->user()->role !== 'babysitter') {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.only_sitters_access_dashboard'),
            ], 403);
        }

        $bookings = Booking::query()
            ->with(['customer:id,name,avatar'])
            ->where('sitter_id', $request->user()->id)
            ->whereIn('status', ['pending', 'confirmed'])
            ->latest()
            ->take(5)
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => BookingResource::collection($bookings),
        ]);
    }

    public function toggleAvailability(Request $request): JsonResponse
    {
        if ($request->user()->role !== 'babysitter') {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.only_sitters_access_dashboard'),
            ], 403);
        }

        if ($request->user()->is_suspended) {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.account_suspended_availability'),
            ], 403);
        }

        $profile = $request->user()->babysitterProfile;

        if ($profile === null) {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.sitter_profile_not_found'),
            ], 404);
        }

        $profile->update([
            'is_available' => ! $profile->is_available,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => $profile->fresh()->is_available
                ? 'You are now available for bookings.'
                : 'You are now unavailable for bookings.',
            'data' => [
                'isAvailable' => $profile->fresh()->is_available,
            ],
        ]);
    }

    public function earningsBreakdown(Request $request): JsonResponse
    {
        if ($request->user()->role !== 'babysitter') {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.only_sitters_access_earnings'),
            ], 403);
        }

        $aggregates = Booking::query()
            ->where('sitter_id', $request->user()->id)
            ->where('status', 'completed')
            ->selectRaw('
                COALESCE(SUM(base_amount), 0) as base_earnings,
                COALESCE(SUM(extra_amount), 0) as extra_earnings,
                COALESCE(SUM(special_needs_amount), 0) as special_needs_earnings,
                COALESCE(SUM(total_amount), 0) as total_earnings,
                COUNT(*) as total_completed_bookings
            ')
            ->first();

        $pendingEarnings = Booking::query()
            ->where('sitter_id', $request->user()->id)
            ->whereIn('status', ['confirmed', 'in_progress'])
            ->sum('total_amount');

        $profile = $request->user()->babysitterProfile;

        return response()->json([
            'status' => 'success',
            'data' => [
                'baseEarnings' => (int) ($aggregates->base_earnings ?? 0),
                'extraEarnings' => (int) ($aggregates->extra_earnings ?? 0),
                'specialNeedsEarnings' => (int) ($aggregates->special_needs_earnings ?? 0),
                'totalEarnings' => (int) ($aggregates->total_earnings ?? 0),
                'pendingEarnings' => (int) $pendingEarnings,
                'totalCompletedBookings' => (int) ($aggregates->total_completed_bookings ?? 0),
                'completedEarnings' => (int) ($profile->total_earnings ?? 0),
            ],
        ]);
    }

    public function trends(Request $request): JsonResponse
    {
        if ($request->user()->role !== 'babysitter') {
            return response()->json([
                'status' => 'error',
                'message' => __('messages.only_sitters_access_analytics'),
            ], 403);
        }

        $monthsBack = min((int) ($request->input('months', 12)), 24);

        $monthlyBookings = Booking::query()
            ->where('sitter_id', $request->user()->id)
            ->where('created_at', '>=', now()->subMonths($monthsBack)->startOfMonth())
            ->selectRaw("
                DATE_FORMAT(created_at, '%Y-%m') as month,
                COUNT(*) as total,
                SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed,
                SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) as cancelled,
                SUM(CASE WHEN status = 'rejected' THEN 1 ELSE 0 END) as rejected,
                COALESCE(SUM(CASE WHEN status = 'completed' THEN total_amount ELSE 0 END), 0) as revenue
            ")
            ->groupByRaw("DATE_FORMAT(created_at, '%Y-%m')")
            ->orderBy('month')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => [
                'months' => $monthsBack,
                'monthlyData' => $monthlyBookings->map(fn ($row) => [
                    'month' => $row->month,
                    'bookings' => (int) $row->total,
                    'completed' => (int) $row->completed,
                    'cancelled' => (int) $row->cancelled,
                    'rejected' => (int) $row->rejected,
                    'revenue' => (int) $row->revenue,
                ]),
            ],
        ]);
    }

    public function followers(Request $request): AnonymousResourceCollection
    {
        if ($request->user()->role !== 'babysitter') {
            abort(403, 'Only babysitters can access followers.');
        }

        $sitterId = $request->user()->id;

        $followerIds = Favorite::query()
            ->where('sitter_id', $sitterId)
            ->orderByDesc('created_at')
            ->pluck('user_id');

        if ($followerIds->isEmpty()) {
            return UserResource::collection(collect());
        }

        $query = User::query()
            ->whereIn('id', $followerIds)
            ->with('babysitterProfile');

        $search = $request->input('search');
        if ($search !== null && $search !== '') {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        $followers = $query->paginate($request->integer('per_page', 20));

        return UserResource::collection($followers);
    }
}
