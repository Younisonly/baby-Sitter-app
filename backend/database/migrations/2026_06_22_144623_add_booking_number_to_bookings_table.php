<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->string('booking_number', 50)->nullable()->unique()->after('id');
        });

        DB::statement('UPDATE bookings SET booking_number = CONCAT("BK-", DATE_FORMAT(created_at, "%Y%m%d"), "-", LPAD(id, 5, "0")) WHERE booking_number IS NULL');

        Schema::table('bookings', function (Blueprint $table) {
            $table->string('booking_number', 50)->nullable(false)->change();
        });
    }

    public function down(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->dropColumn('booking_number');
        });
    }
};
