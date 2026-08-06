<?php

namespace App\Http\Requests\Api\V1;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;

class StoreBookingRequest extends ApiFormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        $hasDates = $this->has('dates');

        $rules = [
            'sitter_id' => ['required', 'exists:users,id'],
            'start_time' => ['required', 'date_format:H:i'],
            'end_time' => ['required', 'date_format:H:i', 'after:start_time'],
            'duration' => ['required', 'integer', 'min:1', 'max:24'],
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

        if ($hasDates) {
            $rules['dates'] = ['required', 'array', 'min:1', 'max:365'];
            $rules['dates.*'] = ['required', 'date', 'after_or_equal:today'];
            $rules['date'] = ['nullable', 'date', 'after_or_equal:today'];
        } else {
            $rules['date'] = ['required', 'date', 'after_or_equal:today'];
        }

        return $rules;
    }

    protected function prepareForValidation(): void
    {
        if ($this->has('dates') && is_array($this->input('dates'))) {
            $dates = $this->input('dates');
            $dates = array_map(function ($date) {
                return is_string($date) ? $date : ($date['date'] ?? $date);
            }, $dates);
            $this->merge(['dates' => array_values(array_unique($dates))]);
        }
    }

    public function messages(): array
    {
        return [
            'children_count.max' => 'This sitter can accept a maximum of :max children.',
            'date.after_or_equal' => 'Bookings must be scheduled for today or a future date.',
            'dates.*.after_or_equal' => 'All booking dates must be today or a future date.',
            'end_time.after' => 'End time must be after start time.',
            'dates.max' => 'A maximum of 365 dates can be booked at once.',
        ];
    }
}
