<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->index(['sitter_id', 'status', 'created_at'], 'bookings_sitter_status_created_idx');
            $table->index(['customer_id', 'status', 'created_at'], 'bookings_customer_status_created_idx');
        });
    }

    public function down(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->dropIndex('bookings_sitter_status_created_idx');
            $table->dropIndex('bookings_customer_status_created_idx');
        });
    }
};
