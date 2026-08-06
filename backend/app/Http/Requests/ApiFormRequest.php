<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest as BaseFormRequest;

/**
 * Base FormRequest for all API requests.
 * Automatically sets the app locale from the Accept-Language header
 * before validation runs, so all error messages are properly localized.
 */
abstract class ApiFormRequest extends BaseFormRequest
{
    /**
     * Override to set the locale BEFORE the validator instance is created.
     * The validator reads trans() at construction time, so locale must be set here.
     */
    protected function getValidatorInstance()
    {
        $locale = $this->header('Accept-Language', 'en');
        $locale = strtolower(trim(explode(',', $locale)[0]));
        $locale = explode('-', $locale)[0];

        if (!in_array($locale, ['en', 'ar'])) {
            $locale = 'en';
        }

        app()->setLocale($locale);

        return parent::getValidatorInstance();
    }
}
