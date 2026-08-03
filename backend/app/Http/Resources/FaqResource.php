<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class FaqResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $locale = $request->header('Accept-Language', 'en');

        return [
            'id' => (string) $this->id,
            'question' => $locale === 'ar' ? $this->question_ar : $this->question_en,
            'answer' => $locale === 'ar' ? $this->answer_ar : $this->answer_en,
            'sort_order' => $this->sort_order,
        ];
    }
}
