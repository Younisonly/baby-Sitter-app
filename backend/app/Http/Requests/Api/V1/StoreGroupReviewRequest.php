<?php

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;

class StoreGroupReviewRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return [
            'rating' => ['required', 'numeric', 'min:0.5', 'max:5'],
            'review' => ['nullable', 'string', 'max:2000'],
        ];
    }

    public function messages(): array
    {
        return [
            'rating.required' => 'Please provide a rating.',
            'rating.min' => 'Rating must be between 0.5 and 5.',
            'rating.max' => 'Rating must be between 0.5 and 5.',
        ];
    }
}
