<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ContactSettingResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => (string) $this->id,
            'email' => $this->email,
            'phone' => $this->phone,
            'whatsapp' => $this->whatsapp,
            'facebook' => $this->facebook,
            'instagram' => $this->instagram,
            'x' => $this->x,
            'website' => $this->website,
        ];
    }
}
