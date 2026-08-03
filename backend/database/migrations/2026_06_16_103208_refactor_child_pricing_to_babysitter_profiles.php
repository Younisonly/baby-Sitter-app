<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('babysitter_profiles', function (Blueprint $table) {
            $table->unsignedTinyInteger('included_children')->default(1)->after('hourly_rate');
            $table->decimal('extra_child_fee', 8, 2)->default(0)->after('included_children');
            $table->unsignedTinyInteger('absolute_max_children')->nullable()->after('extra_child_fee');
        });
    }

    public function down(): void
    {
        Schema::table('babysitter_profiles', function (Blueprint $table) {
            $table->dropColumn(['included_children', 'extra_child_fee', 'absolute_max_children']);
        });
    }
};
