<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('babysitter_profiles', function (Blueprint $table): void {
            $table->unsignedTinyInteger('extra_allowed_children')->default(2)->after('max_children_count');
        });
    }

    public function down(): void
    {
        Schema::table('babysitter_profiles', function (Blueprint $table): void {
            $table->dropColumn('extra_allowed_children');
        });
    }
};
