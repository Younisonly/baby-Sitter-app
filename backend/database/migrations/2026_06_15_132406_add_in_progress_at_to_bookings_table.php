<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('bookings', function (Blueprint $table): void {
            $table->timestamp('in_progress_at')->nullable()->after('confirmed_at');
            $table->index(['sitter_id', 'date', 'status']);
        });
    }

    public function down(): void
    {
        Schema::table('bookings', function (Blueprint $table): void {
            $table->dropColumn('in_progress_at');
            $table->dropIndex(['sitter_id', 'date', 'status']);
        });
    }
};
