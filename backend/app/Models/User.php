<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens;
    use HasFactory;
    use Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'phone',
        'avatar',
        'role',
        'bio',
        'location',
        'latitude',
        'longitude',
        'age',
        'gender',
        'languages',
        'verification_status',
        'registration_status',
        'is_suspended',
        'suspension_reason',
        'suspended_at',
        'email_verified_at',
        'preferred_language',
        'provider',
        'provider_id',
        'national_id',
        'has_parent_profile',
        'has_sitter_profile',
        'became_parent_at',
        'became_sitter_at',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'latitude' => 'decimal:7',
            'longitude' => 'decimal:7',
            'languages' => 'array',
            'is_suspended' => 'boolean',
            'suspended_at' => 'datetime',
            'has_parent_profile' => 'boolean',
            'has_sitter_profile' => 'boolean',
            'became_parent_at' => 'datetime',
            'became_sitter_at' => 'datetime',
            'last_seen_at' => 'datetime',
        ];
    }

    public function scopeNotSuspended(Builder $query): Builder
    {
        return $query->where('is_suspended', false);
    }

    public function babysitterProfile(): HasOne
    {
        return $this->hasOne(BabysitterProfile::class);
    }

    public function parentProfile(): HasOne
    {
        return $this->hasOne(ParentProfile::class);
    }

    public function customerBookings(): HasMany
    {
        return $this->hasMany(Booking::class, 'customer_id');
    }

    public function sitterBookings(): HasMany
    {
        return $this->hasMany(Booking::class, 'sitter_id');
    }

    public function specialSkills(): BelongsToMany
    {
        return $this->belongsToMany(SpecialSkill::class, 'babysitter_special_skill');
    }

    public function favorites(): HasMany
    {
        return $this->hasMany(Favorite::class, 'user_id');
    }

    public function favoritedByUsers(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'favorites', 'sitter_id', 'user_id');
    }

    public function scopeWithIsFavorite(Builder $query, ?int $userId): Builder
    {
        if ($userId === null) {
            return $query;
        }

        return $query->addSelect([
            'is_favorite' => Favorite::query()
                ->selectRaw('1')
                ->whereColumn('sitter_id', 'users.id')
                ->where('user_id', $userId)
                ->limit(1),
        ]);
    }

    public function notificationSettings(): HasOne
    {
        return $this->hasOne(UserNotificationSetting::class);
    }

    public function devices(): HasMany
    {
        return $this->hasMany(UserDevice::class);
    }

    public function appNotifications(): HasMany
    {
        return $this->hasMany(Notification::class, 'user_id');
    }

    public function followers(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'favorites', 'sitter_id', 'user_id');
    }

    public function following(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'favorites', 'user_id', 'sitter_id');
    }

    public function canActAsParent(): bool
    {
        return $this->has_parent_profile || $this->role === 'babysitter';
    }

    public function canActAsSitter(): bool
    {
        return ($this->has_sitter_profile || $this->role === 'babysitter')
            && $this->babysitterProfile !== null;
    }

    public function hasMultipleRoles(): bool
    {
        return $this->canActAsParent() && $this->canActAsSitter();
    }

    public function availableRoles(): array
    {
        $roles = [];
        if ($this->canActAsParent()) {
            $roles[] = 'parent';
        }
        if ($this->canActAsSitter()) {
            $roles[] = 'sitter';
        }
        return $roles;
    }
}
