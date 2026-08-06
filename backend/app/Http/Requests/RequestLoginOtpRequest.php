<?php

namespace App\Http\Requests;

use Illuminate\Validation\Rule;

class RequestLoginOtpRequest extends ApiFormRequest
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
            'channel' => ['sometimes', 'string', Rule::in(['email', 'phone'])],
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
