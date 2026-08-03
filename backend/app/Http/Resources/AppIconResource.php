<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AppIconResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $locale = $request->header('Accept-Language', 'en');

        return [
            'key' => $this->key,
            'label' => $locale === 'ar' && $this->label_ar
                ? $this->label_ar
                : $this->label,
            'category' => $this->category,
            'category_label' => $this->getCategoryLabel($locale),
            'family' => $this->family,
            'keywords' => $this->keywords,
        ];
    }

    private function getCategoryLabel(string $locale): string
    {
        $categories = $locale === 'ar'
            ? \App\Models\AppIcon::categoriesAr()
            : \App\Models\AppIcon::categories();

        return $categories[$this->category] ?? $this->category;
    }
}
