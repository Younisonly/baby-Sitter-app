<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Database\Eloquent\Builder;

final class SitterSearchService
{
    public function buildQuery(array $filters): Builder
    {
        $query = User::query()
            ->where('role', 'babysitter')
            ->where('verification_status', 'verified')
            ->notSuspended()
            ->with('babysitterProfile')
            ->whereHas('babysitterProfile', function (Builder $q) use ($filters): void {
                $q->where('is_available', true);

                if (! empty($filters['category'])) {
                    $q->whereJsonContains('categories', $filters['category']);
                }

                if (! empty($filters['min_price'])) {
                    $q->where('hourly_rate', '>=', (float) $filters['min_price']);
                }

                if (! empty($filters['max_price'])) {
                    $q->where('hourly_rate', '<=', (float) $filters['max_price']);
                }

                if (! empty($filters['min_rating'])) {
                    $q->where('rating', '>=', (float) $filters['min_rating']);
                }

                if (! empty($filters['emergency'])) {
                    $q->where('offers_emergency', true);
                }

                if (! empty($filters['overnight'])) {
                    $q->where('offers_overnight', true);
                }
            });

        if (! empty($filters['search'])) {
            $search = $filters['search'];
            $query->where(function (Builder $q) use ($search): void {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('location', 'like', "%{$search}%");
            });
        }

        if (! empty($filters['city'])) {
            $query->where('location', 'like', '%'.$filters['city'].'%');
        }

        if (! empty($filters['skills'])) {
            $skillKeys = explode(',', $filters['skills']);
            $query->whereHas('specialSkills', function (Builder $q) use ($skillKeys): void {
                $q->whereIn('key', $skillKeys);
            });
        }

        $this->applySorting($query, $filters['sort'] ?? 'featured');

        return $query;
    }

    private function applySorting(Builder $query, string $sort): void
    {
        match ($sort) {
            'top_rated' => $query
                ->join('babysitter_profiles', 'users.id', '=', 'babysitter_profiles.user_id')
                ->orderByDesc('babysitter_profiles.rating')
                ->orderByDesc('babysitter_profiles.review_count')
                ->select('users.*'),
            'price_low' => $query
                ->join('babysitter_profiles', 'users.id', '=', 'babysitter_profiles.user_id')
                ->orderBy('babysitter_profiles.hourly_rate')
                ->select('users.*'),
            'price_high' => $query
                ->join('babysitter_profiles', 'users.id', '=', 'babysitter_profiles.user_id')
                ->orderByDesc('babysitter_profiles.hourly_rate')
                ->select('users.*'),
            'newest' => $query->latest('users.created_at'),
            default => $query
                ->join('babysitter_profiles', 'users.id', '=', 'babysitter_profiles.user_id')
                ->orderByDesc('babysitter_profiles.rating')
                ->orderByDesc('babysitter_profiles.completed_bookings')
                ->select('users.*'),
        };
    }
}
