<?php

namespace App\Policies;

use App\Models\User;

final class FavoritePolicy
{
    public function viewAny(User $user): bool
    {
        return true;
    }

    public function create(User $user, User $sitter): bool
    {
        return $sitter->role === 'babysitter';
    }

    public function delete(User $user, User $sitter): bool
    {
        return true;
    }
}
