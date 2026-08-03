<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'avatar' => $this->avatar,
            'role' => $this->role,
            'bio' => $this->bio,
            'location' => $this->location,
            'latitude' => $this->latitude === null ? null : (float) $this->latitude,
            'longitude' => $this->longitude === null ? null : (float) $this->longitude,
            'age' => $this->age,
            'gender' => $this->gender,
            'languages' => $this->languages,
            'nationalId' => $this->national_id,
            'isVerified' => $this->verification_status === 'verified',
            'verificationStatus' => $this->verification_status,
            'registrationStatus' => $this->registration_status ?? 'none',
            'isSuspended' => (bool) ($this->is_suspended ?? false),
            'suspensionReason' => $this->suspension_reason,
            'isActiveSitter' => $this->role === 'babysitter'
                && $this->verification_status === 'verified'
                && !$this->is_suspended,
            'hasParentProfile' => (bool) $this->has_parent_profile || $this->role === 'babysitter',
            'hasSitterProfile' => (bool) $this->has_sitter_profile || $this->role === 'babysitter',
            'availableRoles' => $this->availableRoles(),
            'createdAt' => $this->created_at?->toJSON(),
            'updatedAt' => $this->updated_at?->toJSON(),
            'isFavorite' => (bool) ($this->is_favorite ?? false),
            'babysitterProfile' => $this->whenLoaded(
                'babysitterProfile',
                fn () => $this->babysitterProfile
                    ? new BabysitterProfileResource($this->babysitterProfile)
                    : null,
                null
            ),
        ];
    }
}
