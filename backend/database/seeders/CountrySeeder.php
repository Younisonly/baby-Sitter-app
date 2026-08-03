<?php

namespace Database\Seeders;

use App\Models\Country;
use Illuminate\Database\Seeder;

class CountrySeeder extends Seeder
{
    public function run(): void
    {
        Country::updateOrCreate(
            ['code' => 'SA'],
            ['name' => 'Saudi Arabia', 'is_active' => true]
        );
    }
}
