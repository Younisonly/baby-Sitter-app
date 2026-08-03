<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreNotificationRequest extends FormRequest
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
