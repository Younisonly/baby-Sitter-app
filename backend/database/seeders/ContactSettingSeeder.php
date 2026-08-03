<?php

namespace Database\Seeders;

use App\Models\ContactSetting;
use Illuminate\Database\Seeder;

class ContactSettingSeeder extends Seeder
{
    public function run(): void
    {
        ContactSetting::create([
            'email' => 'support@babysitter.com',
            'phone' => '+962 79 000 0000',
            'whatsapp' => 'https://wa.me/962790000000',
            'facebook' => 'https://facebook.com/babysitter',
            'instagram' => 'https://instagram.com/babysitter',
            'x' => 'https://x.com/babysitter',
            'website' => 'https://babysitter.com',
        ]);
    }
}
