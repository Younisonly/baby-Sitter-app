<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('app_icons', function (Blueprint $table) {
            $table->id();
            $table->string('key', 50)->unique();
            $table->string('label', 100);
            $table->string('label_ar', 100)->nullable();
            $table->string('category', 50)->index();
            $table->string('family', 20)->default('material');
            $table->string('keywords', 255)->nullable();
            $table->boolean('is_active')->default(true);
            $table->integer('sort_order')->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('app_icons');
    }
};
