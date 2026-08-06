<?php

namespace App\Http\Requests\Api\V1;

use App\Http\Requests\ApiFormRequest;

class UpdateMessageRequest extends ApiFormRequest
{
    public function authorize(): bool
    {
        $message = $this->route('message');

        return $message !== null && (int) $message->sender_id === (int) $this->user()->id;
    }

    public function rules(): array
    {
        return [
            'content' => ['required', 'string', 'max:5000'],
        ];
    }
}
