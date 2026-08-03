<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_notification_settings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->boolean('booking_enabled')->default(true);
            $table->boolean('chat_enabled')->default(true);
            $table->boolean('review_enabled')->default(true);
            $table->boolean('followers_enabled')->default(true);
            $table->boolean('support_enabled')->default(true);
            $table->boolean('security_enabled')->default(true);
            $table->boolean('promotion_enabled')->default(false);
            $table->boolean('push_enabled')->default(true);
            $table->boolean('in_app_enabled')->default(true);
            $table->string('quiet_hours_start', 5)->nullable();
            $table->string('quiet_hours_end', 5)->nullable();
            $table->timestamps();

            $table->unique('user_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_notification_settings');
    }
};
