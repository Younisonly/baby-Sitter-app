<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('special_skills', function (Blueprint $table): void {
            $table->id();
            $table->string('key')->unique();
            $table->string('label');
            $table->string('icon')->default('child_care');
            $table->unsignedSmallInteger('sort_order')->default(0)->index();
            $table->boolean('is_active')->default(true)->index();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('special_skills');
    }
};
