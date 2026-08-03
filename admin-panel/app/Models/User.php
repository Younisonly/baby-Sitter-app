<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Filament\Models\Contracts\FilamentUser;
use Filament\Panel;

class User extends Authenticatable implements FilamentUser
{
    use Notifiable;

    public function canAccessPanel(Panel $panel): bool
    {
        return $this->role === 'admin' && !$this->is_suspended;
    }

    protected $fillable = [
        'name', 'email', 'phone', 'password', 'avatar', 'role',
        'bio', 'location', 'latitude', 'longitude', 'age', 'gender',
        'languages', 'verification_status', 'registration_status',
        'is_suspended', 'suspension_reason', 'suspended_at',
        'email_verified_at', 'preferred_language',
        'provider', 'provider_id', 'national_id',
        'has_parent_profile', 'has_sitter_profile',
        'became_parent_at', 'became_sitter_at', 'last_seen_at',
    ];

    protected $hidden = ['password', 'remember_token'];

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

    public function devices(): HasMany
    {
        return $this->hasMany(UserDevice::class);
    }

    public function specialSkills(): BelongsToMany
    {
        return $this->belongsToMany(SpecialSkill::class, 'babysitter_special_skill', 'user_id', 'special_skill_id');
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    public function isBabysitter(): bool
    {
        return $this->role === 'babysitter';
    }

    public function isCustomer(): bool
    {
        return $this->role === 'customer';
    }

    public function scopeVerified($query)
    {
        return $query->where('verification_status', 'verified');
    }

    public function scopeSuspended($query)
    {
        return $query->where('is_suspended', true);
    }

    public function scopeActive($query)
    {
        return $query->where('is_suspended', false);
    }

    public function scopeByRole($query, string $role)
    {
        return $query->where('role', $role);
    }
}
