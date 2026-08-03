<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notification_audit_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('notification_id')->nullable()->constrained('notifications')->nullOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('template_id')->nullable()->constrained('notification_templates')->nullOnDelete();
            $table->string('action_key', 100)->nullable();
            $table->string('channel', 50); // push, in_app, email, sms
            $table->string('status', 50); // sent, delivered, failed, read
            $table->text('error_message')->nullable();
            $table->timestamps();

            $table->index('action_key');
            $table->index('channel');
            $table->index('status');
            $table->index('created_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notification_audit_logs');
    }
};
