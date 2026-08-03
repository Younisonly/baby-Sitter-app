<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('messages', function (Blueprint $table) {
            $table->index('sender_id', 'idx_messages_sender_id');
        });

        Schema::table('cancellation_policies', function (Blueprint $table) {
            $table->index('is_active', 'idx_cancellation_policies_active');
        });
    }

    public function down(): void
    {
        Schema::table('messages', function (Blueprint $table) {
            $table->dropIndex('idx_messages_sender_id');
        });

        Schema::table('cancellation_policies', function (Blueprint $table) {
            $table->dropIndex('idx_cancellation_policies_active');
        });
    }
};
