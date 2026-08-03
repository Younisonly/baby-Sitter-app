<?php

namespace Database\Seeders;

use App\Models\Language;
use Illuminate\Database\Seeder;

class LanguageSeeder extends Seeder
{
    public function run(): void
    {
        $languages = [
            ['name' => 'Arabic', 'name_ar' => 'العربية'],
            ['name' => 'English', 'name_ar' => 'الإنجليزية'],
            ['name' => 'French', 'name_ar' => 'الفرنسية'],
            ['name' => 'German', 'name_ar' => 'الألمانية'],
            ['name' => 'Spanish', 'name_ar' => 'الإسبانية'],
            ['name' => 'Italian', 'name_ar' => 'الإيطالية'],
            ['name' => 'Turkish', 'name_ar' => 'التركية'],
            ['name' => 'Chinese', 'name_ar' => 'الصينية'],
            ['name' => 'Japanese', 'name_ar' => 'اليابانية'],
            ['name' => 'Russian', 'name_ar' => 'الروسية'],
            ['name' => 'Portuguese', 'name_ar' => 'البرتغالية'],
            ['name' => 'Dutch', 'name_ar' => 'الهولندية'],
            ['name' => 'Korean', 'name_ar' => 'الكورية'],
            ['name' => 'Hindi', 'name_ar' => 'الهندية'],
            ['name' => 'Urdu', 'name_ar' => 'الأردية'],
            ['name' => 'Swahili', 'name_ar' => 'السواحيلية'],
            ['name' => 'Greek', 'name_ar' => 'اليونانية'],
            ['name' => 'Hebrew', 'name_ar' => 'العبرية'],
        ];

        foreach ($languages as $lang) {
            Language::create($lang);
        }
    }
}
