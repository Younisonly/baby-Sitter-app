<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SpecialSkillResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $locale = $request->header('Accept-Language', 'en');

        return [
            'key' => $this->key,
            'label' => $locale === 'ar' && $this->label_ar
                ? $this->label_ar
                : $this->label,
            'icon' => $this->icon,
        ];
    }
}
