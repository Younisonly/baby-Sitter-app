<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('conversations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('participant_one_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('participant_two_id')->constrained('users')->cascadeOnDelete();
            $table->text('last_message_content')->nullable();
            $table->timestamp('last_message_at')->nullable();
            $table->foreignId('last_sender_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->unique(['participant_one_id', 'participant_two_id']);
            $table->index('participant_one_id');
            $table->index('participant_two_id');
            $table->index('last_message_at');
        });

        Schema::create('messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('conversation_id')->constrained()->cascadeOnDelete();
            $table->foreignId('sender_id')->constrained('users')->cascadeOnDelete();
            $table->text('content');
            $table->string('type', 20)->default('text');
            $table->string('image_url', 500)->nullable();
            $table->timestamp('read_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['conversation_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('messages');
        Schema::dropIfExists('conversations');
    }
};
