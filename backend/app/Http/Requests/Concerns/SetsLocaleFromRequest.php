<?php

namespace App\Http\Requests\Concerns;

trait SetsLocaleFromRequest
{
    /**
     * Called by Laravel's FormRequest infrastructure before validation runs.
     * Sets the application locale from the Accept-Language header so that
     * validation messages are returned in the correct language.
     */
    protected function prepareForValidation(): void
    {
        $locale = $this->header('Accept-Language', 'en');
        $locale = strtolower(trim(explode(',', $locale)[0]));
        $locale = explode('-', $locale)[0];

        if (!in_array($locale, ['en', 'ar'])) {
            $locale = 'en';
        }

        app()->setLocale($locale);
    }
}
