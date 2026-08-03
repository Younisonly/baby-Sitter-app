<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('babysitter_profiles', function (Blueprint $table): void {
            $table->foreignId('cancellation_policy_id')
                ->nullable()
                ->after('is_available')
                ->constrained('cancellation_policies')
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('babysitter_profiles', function (Blueprint $table): void {
            $table->dropForeign(['cancellation_policy_id']);
            $table->dropColumn('cancellation_policy_id');
        });
    }
};
