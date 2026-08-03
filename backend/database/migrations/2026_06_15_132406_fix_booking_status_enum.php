<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $driver = DB::connection()->getDriverName();

        if ($driver === 'mysql' || $driver === 'mariadb') {
            DB::statement("ALTER TABLE bookings MODIFY COLUMN status ENUM(
                'pending', 'confirmed', 'in_progress', 'completed',
                'cancelled', 'rejected', 'expired'
            ) NOT NULL DEFAULT 'pending'");
        }
    }

    public function down(): void
    {
        $driver = DB::connection()->getDriverName();

        if ($driver === 'mysql' || $driver === 'mariadb') {
            DB::statement("ALTER TABLE bookings MODIFY COLUMN status ENUM(
                'pending', 'confirmed', 'in_progress', 'completed', 'cancelled'
            ) NOT NULL DEFAULT 'pending'");
        }
    }
};
