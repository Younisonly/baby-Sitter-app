<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Password;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:50'],
            'email' => ['required', 'email:rfc,dns', 'max:255', 'unique:users,email'],
            'phone' => ['nullable', 'string', 'max:20', 'unique:users,phone'],
            'password' => ['required', 'confirmed', Password::min(8)->mixedCase()->numbers()],
            'role' => ['nullable', 'string', 'in:customer,babysitter'],
            'national_id' => [
                'nullable',
                'string',
                'max:20',
                'unique:users,national_id',
                'required_if:role,babysitter',
            ],
            'preferred_language' => ['nullable', 'string', 'in:en,ar'],
        ];
    }

    public function messages(): array
    {
        return [
            'national_id.required_if' => 'National ID is required for babysitter registration.',
        ];
    }
}
