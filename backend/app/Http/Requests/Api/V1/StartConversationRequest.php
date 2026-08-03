<?php

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;

class StartConversationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'other_user_id' => ['required', 'integer', 'exists:users,id', 'different:user_id'],
        ];
    }

    protected function prepareForValidation(): void
    {
        $this->merge(['user_id' => $this->user()?->id]);
    }
}
