<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->boolean('is_day_completed')->default(false)->after('session_status');
            $table->timestamp('day_completed_at')->nullable()->after('is_day_completed');
        });
    }

    public function down(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->dropColumn(['is_day_completed', 'day_completed_at']);
        });
    }
};
