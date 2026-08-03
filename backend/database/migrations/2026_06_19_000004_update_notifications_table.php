<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('notifications', function (Blueprint $table) {
            if (!Schema::hasColumn('notifications', 'template_id')) {
                $table->foreignId('template_id')->nullable()->constrained('notification_templates')->nullOnDelete();
            }
            if (!Schema::hasColumn('notifications', 'language')) {
                $table->string('language', 5)->default('en');
            }
            if (!Schema::hasColumn('notifications', 'data_json')) {
                $table->json('data_json')->nullable();
            }
            if (Schema::hasColumn('notifications', 'data')) {
                $table->dropColumn('data');
            }
            if (!Schema::hasColumn('notifications', 'read_at')) {
                $table->timestamp('read_at')->nullable();
                $table->dropColumn('is_read');
                $table->boolean('is_read')->default(false);
            }
            if (!Schema::hasColumn('notifications', 'priority')) {
                $table->string('priority', 20)->default('normal');
            }
            if (!Schema::hasColumn('notifications', 'icon')) {
                $table->string('icon', 100)->nullable();
            }
            if (!Schema::hasColumn('notifications', 'image')) {
                $table->string('image', 500)->nullable();
            }
            if (!Schema::hasColumn('notifications', 'deep_link_type')) {
                $table->string('deep_link_type', 100)->nullable();
            }
            if (!Schema::hasColumn('notifications', 'deep_link_id')) {
                $table->string('deep_link_id', 100)->nullable();
            }
            if (!Schema::hasColumn('notifications', 'show_push')) {
                $table->boolean('show_push')->default(true);
            }
            if (!Schema::hasColumn('notifications', 'show_in_app')) {
                $table->boolean('show_in_app')->default(true);
            }
            if (!Schema::hasColumn('notifications', 'action_key')) {
                $table->string('action_key', 100)->nullable();
            }

            $table->index('action_key');
            $table->index('priority');
            $table->index('read_at');
        });
    }

    public function down(): void
    {
        Schema::table('notifications', function (Blueprint $table) {
            $table->dropForeign(['template_id']);
            $table->dropColumn([
                'template_id', 'language', 'data_json', 'read_at',
                'priority', 'icon', 'image', 'deep_link_type',
                'deep_link_id', 'show_push', 'show_in_app', 'action_key',
            ]);
        });
    }
};
