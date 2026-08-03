<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('messages', function (Blueprint $table) {
            $table->foreignId('reply_to_id')
                ->nullable()
                ->after('image_url')
                ->constrained('messages')
                ->nullOnDelete();

            $table->string('message_type', 20)
                ->default('text')
                ->after('reply_to_id');

            $table->json('metadata')
                ->nullable()
                ->after('message_type');

            $table->boolean('is_system')
                ->default(false)
                ->after('metadata');

            $table->index('message_type');
        });

        Schema::table('conversations', function (Blueprint $table) {
            $table->string('last_message_type', 20)->nullable()->after('last_message_content');
        });

        Schema::create('message_reactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('message_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('reaction', 50);
            $table->timestamp('created_at')->nullable();

            $table->unique(['message_id', 'user_id', 'reaction']);
        });

        Schema::create('message_attachments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('message_id')->constrained()->cascadeOnDelete();
            $table->string('file_path', 500);
            $table->string('file_name', 255);
            $table->bigInteger('file_size');
            $table->string('mime_type', 100);
            $table->enum('file_type', ['image', 'voice', 'file', 'document']);
            $table->timestamp('created_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('message_attachments');
        Schema::dropIfExists('message_reactions');

        Schema::table('conversations', function (Blueprint $table) {
            $table->dropColumn('last_message_type');
        });

        Schema::table('messages', function (Blueprint $table) {
            $table->dropColumn(['reply_to_id', 'message_type', 'metadata', 'is_system']);
        });
    }
};
