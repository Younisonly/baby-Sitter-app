<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\Favorite;
use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class FavoriteController extends Controller
{
    public function __construct(
        private readonly NotificationService $notificationService,
    ) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        $sitterIds = Favorite::query()
            ->where('user_id', $request->user()->id)
            ->orderByDesc('created_at')
            ->pluck('sitter_id');

        if ($sitterIds->isEmpty()) {
            return UserResource::collection(collect());
        }

        $orderedIds = $sitterIds->toArray();
        $idString = implode(',', array_map('intval', $orderedIds));

        $sitters = User::query()
            ->where('role', 'babysitter')
            ->with('babysitterProfile')
            ->whereIn('id', $orderedIds)
            ->orderByRaw('FIELD(id,' . $idString . ')')
            ->paginate($request->integer('per_page', 20));

        return UserResource::collection($sitters);
    }

    public function store(Request $request, User $sitter): JsonResponse
    {
        if ($sitter->role !== 'babysitter') {
            return response()->json([
                'status' => 'error',
                'message' => __('Sitter not found.'),
            ], 404);
        }

        if ($request->user()->id === $sitter->id) {
            return response()->json([
                'status' => 'error',
                'message' => __('You cannot favorite yourself.'),
            ], 400);
        }

        DB::beginTransaction();
        try {
            $exists = Favorite::query()
                ->where('user_id', $request->user()->id)
                ->where('sitter_id', $sitter->id)
                ->exists();

            if ($exists) {
                DB::rollBack();
                return response()->json([
                    'status' => 'success',
                    'message' => __('Sitter added to favorites.'),
                ], 201);
            }

            DB::table('favorites')->insert([
                'user_id' => $request->user()->id,
                'sitter_id' => $sitter->id,
                'created_at' => now(),
            ]);

            if ($sitter->babysitterProfile) {
                $sitter->babysitterProfile->increment('follower_count');
            }

            DB::commit();

            try {
                $this->notificationService->send(
                    $sitter,
                    'new_favorite',
                    ['follower_name' => $request->user()->name],
                    (string) $request->user()->id,
                );
            } catch (\Exception $e) {
                Log::error("Failed to send new_favorite notification to sitter {$sitter->id}: {$e->getMessage()}");
            }
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error("Failed to add favorite for sitter {$sitter->id}: {$e->getMessage()}");
            return response()->json([
                'status' => 'error',
                'message' => __('Failed to add favorite. Please try again.'),
            ], 500);
        }

        return response()->json([
            'status' => 'success',
            'message' => __('Sitter added to favorites.'),
        ], 201);
    }

    public function destroy(Request $request, User $sitter): JsonResponse
    {
        if ($request->user()->id === $sitter->id) {
            return response()->json([
                'status' => 'error',
                'message' => __('You cannot unfavorite yourself.'),
            ], 400);
        }

        DB::beginTransaction();
        try {
            $deleted = Favorite::query()
                ->where('user_id', $request->user()->id)
                ->where('sitter_id', $sitter->id)
                ->delete();

            if ($deleted > 0) {
                $profile = $sitter->babysitterProfile;
                if ($profile && $profile->follower_count > 0) {
                    $profile->decrement('follower_count');
                }
            }

            DB::commit();
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error("Failed to remove favorite for sitter {$sitter->id}: {$e->getMessage()}");
            return response()->json([
                'status' => 'error',
                'message' => __('Failed to remove favorite. Please try again.'),
            ], 500);
        }

        return response()->json([
            'status' => 'success',
            'message' => __('Sitter removed from favorites.'),
        ], 200);
    }
}
