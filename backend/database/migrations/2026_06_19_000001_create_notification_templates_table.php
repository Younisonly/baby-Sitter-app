<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notification_templates', function (Blueprint $table) {
            $table->id();
            $table->string('action_key', 100)->unique();
            $table->string('title_en', 255);
            $table->string('title_ar', 255);
            $table->text('body_en');
            $table->text('body_ar');
            $table->string('category', 50)->default('system');
            $table->string('priority', 20)->default('normal');
            $table->boolean('allow_push')->default(true);
            $table->boolean('allow_in_app')->default(true);
            $table->boolean('allow_email')->default(false);
            $table->boolean('allow_sms')->default(false);
            $table->string('icon', 100)->nullable();
            $table->string('deep_link_type', 100)->nullable();
            $table->timestamps();

            $table->index('category');
            $table->index('priority');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notification_templates');
    }
};
