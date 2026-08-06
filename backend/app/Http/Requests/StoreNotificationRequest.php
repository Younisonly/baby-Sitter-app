<?php

namespace App\Http\Requests;

use App\Http\Requests\ApiFormRequest;

class StoreNotificationRequest extends ApiFormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return [
            'user_id' => ['required', 'exists:users,id'],
            'title' => ['required', 'string', 'max:255'],
            'body' => ['required', 'string'],
            'type' => ['nullable', 'string', 'in:booking,chat,review,payment,system,promotion'],
            'image_url' => ['nullable', 'url'],
            'action_url' => ['nullable', 'string', 'max:500'],
        ];
    }
}
