<?php

namespace App\Http\Requests;

class VerifyLoginOtpRequest extends ApiFormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'otp_token' => ['required', 'string'],
            'otp' => ['required', 'digits:6'],
            'device_name' => ['nullable', 'string', 'max:80'],
        ];
    }
}
