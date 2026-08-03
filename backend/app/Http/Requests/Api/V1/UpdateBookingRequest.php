<?php

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;

class UpdateBookingRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null && in_array($this->user()->role, ['customer', 'babysitter']);
    }

    public function rules(): array
    {
        return [
            'date' => ['sometimes', 'date', 'after_or_equal:today'],
            'start_time' => ['sometimes', 'date_format:H:i'],
            'end_time' => ['sometimes', 'date_format:H:i', 'after:start_time'],
            'duration' => ['sometimes', 'integer', 'min:1', 'max:24'],
            'address' => ['nullable', 'string', 'max:255'],
            'children_count' => ['nullable', 'integer', 'min:1', 'max:12'],
            'special_needs_count' => ['nullable', 'integer', 'min:0', 'max:10'],
            'children_ages' => ['nullable', 'array', 'max:10'],
            'children_ages.*' => ['string', 'max:20'],
            'children_names' => ['nullable', 'array', 'max:10'],
            'children_names.*' => ['string', 'max:50'],
            'notes' => ['nullable', 'string', 'max:1000'],
            'special_instructions' => ['nullable', 'string', 'max:1000'],
            'schedule_events' => ['nullable', 'array', 'max:24'],
            'schedule_events.*.time' => ['required_with:schedule_events', 'string', 'max:10'],
            'schedule_events.*.activity' => ['required_with:schedule_events', 'string', 'max:255'],
        ];
    }

    public function messages(): array
    {
        return [
            'children_count.max' => 'This sitter can accept a maximum of :max children.',
            'date.after_or_equal' => 'Bookings must be scheduled for today or a future date.',
            'end_time.after' => 'End time must be after start time.',
        ];
    }
}
