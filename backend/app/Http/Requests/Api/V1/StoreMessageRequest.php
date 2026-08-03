<?php

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;

class StoreMessageRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'content' => ['nullable', 'string', 'max:5000', 'required_without:image_url'],
            'type' => ['nullable', 'string', 'in:text,image,voice,file'],
            'image_url' => ['nullable', 'string', 'max:500'],
            'reply_to_id' => ['nullable', 'integer', 'exists:messages,id'],
            'message_type' => ['nullable', 'string', 'in:text,image,voice,file,system'],
            'metadata' => ['nullable', 'json'],
        ];
    }
}
