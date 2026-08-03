<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('babysitter_profiles', function (Blueprint $table): void {
            $table->unsignedTinyInteger('base_children_count')->default(1)->after('hourly_rate');
            $table->decimal('extra_child_rate', 8, 2)->default(0)->after('base_children_count');
            $table->decimal('special_needs_rate', 8, 2)->default(0)->after('extra_child_rate');
        });
    }

    public function down(): void
    {
        Schema::table('babysitter_profiles', function (Blueprint $table): void {
            $table->dropColumn(['base_children_count', 'extra_child_rate', 'special_needs_rate']);
        });
    }
};
