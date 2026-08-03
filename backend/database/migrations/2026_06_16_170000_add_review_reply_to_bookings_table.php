<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->text('reply')->nullable()->after('review');
            $table->timestamp('replied_at')->nullable()->after('reply');
            $table->integer('helpful_count')->default(0)->after('replied_at');
            $table->timestamp('reported_at')->nullable()->after('helpful_count');
        });
    }

    public function down(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->dropColumn(['reply', 'replied_at', 'helpful_count', 'reported_at']);
        });
    }
};
