<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ReviewResource;
use App\Http\Resources\UserResource;
use App\Models\Booking;
use App\Models\Favorite;
use App\Models\User;
use App\Services\SitterSearchService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Laravel\Sanctum\Sanctum;

class SitterController extends Controller
{
    public function __construct(
        private readonly SitterSearchService $searchService,
    ) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        $validated = $request->validate([
            'category' => ['nullable', 'string', 'max:60'],
            'search' => ['nullable', 'string', 'max:80'],
            'sort' => ['nullable', 'in:featured,top_rated,price_low,price_high,newest,nearest'],
            'lat' => ['nullable', 'numeric'],
            'lng' => ['nullable', 'numeric'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:50'],
            'min_price' => ['nullable', 'numeric', 'min:0', 'max:99999'],
            'max_price' => ['nullable', 'numeric', 'min:0', 'max:99999'],
            'min_rating' => ['nullable', 'numeric', 'min:0', 'max:5'],
            'city' => ['nullable', 'string', 'max:100'],
            'emergency' => ['nullable', 'boolean'],
            'overnight' => ['nullable', 'boolean'],
            'skills' => ['nullable', 'string', 'max:500'],
        ]);

        $query = $this->searchService->buildQuery($validated);

        $currentUserId = $this->optionalAuthUserId();
        if ($currentUserId !== null) {
            $query->withIsFavorite($currentUserId);
        }

        return UserResource::collection(
            $query->paginate($validated['per_page'] ?? 20),
        );
    }

    public function show(User $user): UserResource
    {
        abort_unless($user->role === 'babysitter', 404);

        $currentUserId = $this->optionalAuthUserId();
        $user->load('babysitterProfile');

        if ($user->babysitterProfile) {
            $user->babysitterProfile->increment('view_count');
        }

        $user->loadCount([
            'sitterBookings as completed_bookings' => fn($q) => $q->where('status', 'completed'),
            'sitterBookings as cancelled_bookings' => fn($q) => $q->where('status', 'cancelled'),
        ]);

        if ($currentUserId !== null) {
            $isFav = Favorite::where('user_id', $currentUserId)
                ->where('sitter_id', $user->id)
                ->exists();
            if ($isFav) {
                $user->setAttribute('is_favorite', true);
            }
        }

        $user->unsetRelation('babysitterProfile');
        $user->load('babysitterProfile');

        return UserResource::make($user);
    }

    public function reviews(User $sitter, Request $request): AnonymousResourceCollection
    {
        abort_unless($sitter->role === 'babysitter', 404);

        $reviews = Booking::query()
            ->where('sitter_id', $sitter->id)
            ->whereNotNull('rating')
            ->where('status', 'completed')
            ->with(['customer:id,name,avatar'])
            ->orderByDesc('updated_at')
            ->paginate($request->integer('per_page', 20));

        return ReviewResource::collection($reviews);
    }

    private function optionalAuthUserId(): ?int
    {
        $token = request()->bearerToken();

        if ($token === null) {
            return null;
        }

        $model = Sanctum::$personalAccessTokenModel;
        $accessToken = $model::findToken($token);

        if ($accessToken === null || ! $accessToken->can('*')) {
            return null;
        }

        return $accessToken->tokenable_id;
    }
}
