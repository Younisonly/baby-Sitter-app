<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class NotificationTemplate extends Model
{
    use HasFactory;

    protected $fillable = [
        'action_key',
        'title_en',
        'title_ar',
        'body_en',
        'body_ar',
        'category',
        'priority',
        'allow_push',
        'allow_in_app',
        'allow_email',
        'allow_sms',
        'icon',
        'deep_link_type',
    ];

    protected function casts(): array
    {
        return [
            'allow_push' => 'boolean',
            'allow_in_app' => 'boolean',
            'allow_email' => 'boolean',
            'allow_sms' => 'boolean',
        ];
    }

    public function getTitleAttribute(): string
    {
        return app()->getLocale() === 'ar' ? $this->title_ar : $this->title_en;
    }

    public function getBodyAttribute(): string
    {
        return app()->getLocale() === 'ar' ? $this->body_ar : $this->body_en;
    }

    public function resolveTitle(string $locale, array $replacements = []): string
    {
        $title = $locale === 'ar' ? $this->title_ar : $this->title_en;
        return $this->replaceVariables($title, $replacements);
    }

    public function resolveBody(string $locale, array $replacements = []): string
    {
        $body = $locale === 'ar' ? $this->body_ar : $this->body_en;
        return $this->replaceVariables($body, $replacements);
    }

    private function replaceVariables(string $text, array $replacements): string
    {
        foreach ($replacements as $key => $value) {
            $text = str_replace('{' . $key . '}', (string) $value, $text);
        }
        return $text;
    }

    public function notifications(): HasMany
    {
        return $this->hasMany(Notification::class, 'template_id');
    }
}
