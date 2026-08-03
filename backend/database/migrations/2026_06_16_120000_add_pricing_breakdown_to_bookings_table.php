<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('bookings', function (Blueprint $table): void {
            $table->unsignedInteger('base_amount')->default(0)->after('total_amount');
            $table->unsignedInteger('extra_amount')->default(0)->after('base_amount');
            $table->unsignedInteger('special_needs_amount')->default(0)->after('extra_amount');
        });
    }

    public function down(): void
    {
        Schema::table('bookings', function (Blueprint $table): void {
            $table->dropColumn(['base_amount', 'extra_amount', 'special_needs_amount']);
        });
    }
};
