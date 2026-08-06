<?php

namespace App\Http\Requests\Api\V1;

use App\Http\Requests\ApiFormRequest;

class UpdateSitterProfileRequest extends ApiFormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null && $this->user()->role === 'babysitter';
    }

    public function rules(): array
    {
        return [
            'hourly_rate' => ['nullable', 'numeric', 'min:0', 'max:9999'],
            'included_children' => ['nullable', 'integer', 'min:1', 'max:20'],
            'extra_child_fee' => ['nullable', 'numeric', 'min:0', 'max:9999'],
            'absolute_max_children' => ['nullable', 'integer', 'min:1', 'max:30'],
            'special_needs_rate' => ['nullable', 'numeric', 'min:0', 'max:9999'],
            'availability' => ['nullable', 'array'],
            'availability.*.day_of_week' => ['required_with:availability', 'integer', 'between:0,6'],
            'availability.*.start_time' => ['required_with:availability', 'date_format:H:i'],
            'availability.*.end_time' => ['required_with:availability', 'date_format:H:i', 'after:availability.*.start_time'],
            'description' => ['nullable', 'string', 'max:2000'],
            'certificates' => ['nullable', 'array'],
            'certificates.*' => ['string', 'max:255'],
            'categories' => ['nullable', 'array'],
            'categories.*' => ['string', 'max:50'],
            'years_experience' => ['nullable', 'integer', 'min:0', 'max:70'],
            'bio' => ['nullable', 'string', 'max:1000'],
            'location' => ['nullable', 'string', 'max:120'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'bank_account' => ['nullable', 'string', 'max:100'],
            'gallery_images' => ['nullable', 'array'],
            'gallery_images.*' => ['string', 'max:500'],
        ];
    }
}
