<?php
namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminSeeder extends Seeder
{
    public function run(): void
    {
        User::updateOrCreate(
            ['email' => 'admin@babysitter.com'],
            [
                'name' => 'Admin',
                'password' => Hash::make('AdminPass123'),
                'role' => 'admin',
                'email_verified_at' => now(),
                'verification_status' => 'verified',
                'preferred_language' => 'en',
            ]
        );

        User::updateOrCreate(
            ['email' => 'superadmin@babysitter.com'],
            [
                'name' => 'Super Admin',
                'password' => Hash::make('SuperAdmin123'),
                'role' => 'super_admin',
                'email_verified_at' => now(),
                'verification_status' => 'verified',
                'preferred_language' => 'en',
            ]
        );

        $this->command->info('Admin users seeded successfully!');
    }
}
