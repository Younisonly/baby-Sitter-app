<?php

namespace App\Providers\Filament;

use Filament\FontProviders\Contracts\FontProvider;
use Illuminate\Contracts\Support\Htmlable;
use Illuminate\Support\HtmlString;

class LocalFontProvider implements FontProvider
{
    public function getHtml(string $family, ?string $url = null): Htmlable
    {
        $url ??= asset('fonts/inter.css');

        return new HtmlString("<link href=\"{$url}\" rel=\"stylesheet\" />");
    }
}
