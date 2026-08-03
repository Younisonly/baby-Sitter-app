<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('bookings', function (Blueprint $table): void {
            $table->string('session_status', 20)->default('pending')->index()->after('status');
            $table->text('qr_start_token')->nullable()->after('session_status');
            $table->text('qr_end_token')->nullable()->after('qr_start_token');
            $table->timestamp('session_started_at')->nullable()->after('qr_end_token');
            $table->timestamp('session_ended_at')->nullable()->after('session_started_at');
            $table->timestamp('gps_started_at')->nullable()->after('session_ended_at');
            $table->timestamp('gps_ended_at')->nullable()->after('gps_started_at');
            $table->unsignedInteger('overtime_minutes')->default(0)->after('gps_ended_at');
            $table->unsignedInteger('overtime_cost')->default(0)->after('overtime_minutes');
            $table->unsignedInteger('waiting_minutes')->default(0)->after('overtime_cost');
            $table->unsignedInteger('waiting_cost')->default(0)->after('waiting_minutes');
            $table->decimal('expected_hours', 5, 2)->default(0)->after('waiting_cost');
            $table->decimal('actual_hours', 5, 2)->default(0)->after('expected_hours');
            $table->text('session_notes')->nullable()->after('actual_hours');
        });

        Schema::table('bookings', function (Blueprint $table): void {
            $table->index(['session_status', 'sitter_id']);
            $table->index(['session_status', 'customer_id']);
            $table->index(['qr_start_token'], 'idx_qr_start');
            $table->index(['qr_end_token'], 'idx_qr_end');
        });
    }

    public function down(): void
    {
        Schema::table('bookings', function (Blueprint $table): void {
            $table->dropIndex(['session_status', 'sitter_id']);
            $table->dropIndex(['session_status', 'customer_id']);
            $table->dropIndex('idx_qr_start');
            $table->dropIndex('idx_qr_end');
        });

        Schema::table('bookings', function (Blueprint $table): void {
            $table->dropColumn([
                'session_status',
                'qr_start_token',
                'qr_end_token',
                'session_started_at',
                'session_ended_at',
                'gps_started_at',
                'gps_ended_at',
                'overtime_minutes',
                'overtime_cost',
                'waiting_minutes',
                'waiting_cost',
                'expected_hours',
                'actual_hours',
                'session_notes',
            ]);
        });
    }
};
