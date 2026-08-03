<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('bookings', function (Blueprint $table): void {
            $table->timestamp('confirmed_at')->nullable()->after('cancelled_at');
            $table->timestamp('rejected_at')->nullable()->after('confirmed_at');
            $table->timestamp('expired_at')->nullable()->after('rejected_at');
            $table->text('rejection_reason')->nullable()->after('cancellation_reason');
            $table->json('status_history')->nullable()->default('[]')->after('rejection_reason');
            $table->foreignId('rescheduled_from_id')->nullable()->after('status_history')
                ->constrained('bookings')->nullOnDelete();
            $table->timestamp('confirmation_deadline')->nullable()->after('rescheduled_from_id');

            $table->index(['status', 'customer_id']);
            $table->index(['status', 'sitter_id']);
            $table->index(['status', 'date']);
        });
    }

    public function down(): void
    {
        Schema::table('bookings', function (Blueprint $table): void {
            $table->dropForeign(['rescheduled_from_id']);
            $table->dropColumn([
                'confirmed_at',
                'rejected_at',
                'expired_at',
                'rejection_reason',
                'status_history',
                'rescheduled_from_id',
                'confirmation_deadline',
            ]);

            $table->dropIndex(['status', 'customer_id']);
            $table->dropIndex(['status', 'sitter_id']);
            $table->dropIndex(['status', 'date']);
        });
    }
};
