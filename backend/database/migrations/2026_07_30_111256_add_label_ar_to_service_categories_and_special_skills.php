<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('service_categories', function (Blueprint $table) {
            $table->string('label_ar')->nullable()->after('label');
            $table->text('description_ar')->nullable()->after('description');
        });

        Schema::table('special_skills', function (Blueprint $table) {
            $table->string('label_ar')->nullable()->after('label');
        });
    }

    public function down(): void
    {
        Schema::table('service_categories', function (Blueprint $table) {
            $table->dropColumn(['label_ar', 'description_ar']);
        });

        Schema::table('special_skills', function (Blueprint $table) {
            $table->dropColumn('label_ar');
        });
    }
};
