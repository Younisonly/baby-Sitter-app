<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Session;

class LocaleController extends Controller
{
    public function switch(string $locale)
    {
        if (array_key_exists($locale, config('app.available_locales', []))) {
            Session::put('admin_locale', $locale);
        }

        return redirect()->back();
    }
}
