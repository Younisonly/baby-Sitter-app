<?php

namespace Database\Seeders;

use App\Models\CancellationPolicy;
use Illuminate\Database\Seeder;

class CancellationPolicySeeder extends Seeder
{
    public function run(): void
    {
        CancellationPolicy::upsert([
            [
                'name' => 'Free Cancellation',
                'description' => 'Full refund if cancelled at least 24 hours before the booking start time.',
                'refund_percent' => 100,
                'hours_before' => 24,
                'is_active' => true,
            ],
            [
                'name' => 'Partial Refund',
                'description' => '50% refund if cancelled between 12 and 24 hours before the booking start time.',
                'refund_percent' => 50,
                'hours_before' => 12,
                'is_active' => true,
            ],
            [
                'name' => 'No Refund',
                'description' => 'No refund if cancelled less than 12 hours before the booking start time.',
                'refund_percent' => 0,
                'hours_before' => 0,
                'is_active' => true,
            ],
        ], ['name'], ['description', 'refund_percent', 'hours_before', 'is_active']);
    }
}
