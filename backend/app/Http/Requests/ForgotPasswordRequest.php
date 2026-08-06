<?php

namespace App\Http\Requests;

use Illuminate\Validation\Rule;

class ForgotPasswordRequest extends ApiFormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'email' => ['required_without:phone', 'email:rfc', 'exists:users,email'],
            'phone' => ['required_without:email', 'string', 'max:20', 'exists:users,phone'],
        ];
    }

    public function messages(): array
    {
        return [
            'email.exists' => 'No account found with this email.',
            'phone.exists' => 'No account found with this phone number.',
        ];
    }
}
