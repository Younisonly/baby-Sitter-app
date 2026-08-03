<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CategoryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $locale = $request->header('Accept-Language', 'en');

        return [
            'key' => $this->key,
            'label' => $locale === 'ar' && $this->label_ar
                ? $this->label_ar
                : $this->label,
            'description' => $locale === 'ar' && $this->description_ar
                ? $this->description_ar
                : $this->description,
            'icon' => $this->icon,
            'color' => $this->color,
        ];
    }
}
