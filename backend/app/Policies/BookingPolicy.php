<?php

namespace App\Policies;

use App\Models\Booking;
use App\Models\User;

final class BookingPolicy
{
    public function viewAny(User $user): bool
    {
        return in_array($user->role, ['customer', 'babysitter', 'admin']);
    }

    public function view(User $user, Booking $booking): bool
    {
        return $user->id === $booking->customer_id || $user->id === $booking->sitter_id || $user->role === 'admin';
    }

    public function create(User $user): bool
    {
        return in_array($user->role, ['customer', 'babysitter']);
    }

    public function update(User $user, Booking $booking): bool
    {
        return $user->id === $booking->customer_id || $user->id === $booking->sitter_id;
    }

    public function confirm(User $user, Booking $booking): bool
    {
        return $user->id === $booking->sitter_id;
    }

    public function start(User $user, Booking $booking): bool
    {
        return $user->id === $booking->sitter_id;
    }

    public function viewSitterBookings(User $user, User $sitter): bool
    {
        return $user->id === $sitter->id || $user->role === 'admin' || $user->role === 'parent';
    }
}
