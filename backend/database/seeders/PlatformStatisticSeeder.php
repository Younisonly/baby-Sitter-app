<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class PlatformStatisticSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $stats = [
            [
                'key' => 'sitters',
                'value' => '500+',
                'label' => 'Sitters',
                'label_ar' => 'جليسة',
                'icon' => null,
                'sort_order' => 1,
            ],
            [
                'key' => 'bookings',
                'value' => '10k+',
                'label' => 'Bookings',
                'label_ar' => 'حجز',
                'icon' => null,
                'sort_order' => 2,
            ],
            [
                'key' => 'rating',
                'value' => '4.9',
                'label' => 'Rating',
                'label_ar' => 'تقييم',
                'icon' => 'star_rounded',
                'sort_order' => 3,
            ],
        ];

        foreach ($stats as $stat) {
            \App\Models\PlatformStatistic::updateOrCreate(
                ['key' => $stat['key']],
                $stat
            );
        }
    }
}
