<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('babysitter_profiles', function (Blueprint $table) {
            $table->boolean('offers_emergency')->default(false)->after('is_available');
            $table->boolean('offers_overnight')->default(false)->after('offers_emergency');
        });
    }

    public function down(): void
    {
        Schema::table('babysitter_profiles', function (Blueprint $table) {
            $table->dropColumn(['offers_emergency', 'offers_overnight']);
        });
    }
};
