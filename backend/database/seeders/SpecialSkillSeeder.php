<?php

namespace Database\Seeders;

use App\Models\SpecialSkill;
use Illuminate\Database\Seeder;

class SpecialSkillSeeder extends Seeder
{
    public function run(): void
    {
        $skills = [
            ['key' => 'newborn', 'label' => 'Newborn', 'label_ar' => 'حديثي الولادة', 'icon' => 'child_care', 'sort_order' => 1],
            ['key' => 'toddler', 'label' => 'Toddler', 'label_ar' => 'الأطفال الصغار', 'icon' => 'emoji_people', 'sort_order' => 2],
            ['key' => 'special_needs', 'label' => 'Special Needs', 'label_ar' => 'احتياجات خاصة', 'icon' => 'favorite_border', 'sort_order' => 3],
            ['key' => 'school', 'label' => 'School Age', 'label_ar' => 'سن المدرسة', 'icon' => 'school', 'sort_order' => 4],
        ];

        foreach ($skills as $skill) {
            SpecialSkill::updateOrCreate(['key' => $skill['key']], $skill);
        }
    }
}
