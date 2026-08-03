<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_devices', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('device_token', 500);
            $table->string('platform', 20)->nullable();
            $table->string('app_version', 20)->nullable();
            $table->string('os_version', 50)->nullable();
            $table->string('device_name', 255)->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamp('last_active_at')->nullable();
            $table->timestamps();

            $table->index('device_token');
            $table->index('is_active');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_devices');
    }
};
