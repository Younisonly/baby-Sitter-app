<?php

namespace Database\Seeders;

use App\Models\City;
use App\Models\Country;
use Illuminate\Database\Seeder;

class CitySeeder extends Seeder
{
    public function run(): void
    {
        $country = Country::where('code', 'SA')->first();
        if (! $country) {
            return;
        }

        $cities = [
            'Riyadh', 'Jeddah', 'Mecca', 'Medina', 'Dammam',
            'Khobar', 'Dhahran', 'Taif', 'Tabuk', 'Buraidah',
            'Hail', 'Abha', 'Najran', 'Jubail', 'Yanbu',
            'Al Ahsa', 'Qatif', 'Khamis Mushait', 'Sakaka',
        ];

        foreach ($cities as $name) {
            City::updateOrCreate(
                ['country_id' => $country->id, 'name' => $name],
                ['is_active' => true]
            );
        }
    }
}
