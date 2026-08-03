<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            $table->boolean('has_parent_profile')->after('national_id')->default(false);
            $table->boolean('has_sitter_profile')->after('has_parent_profile')->default(false);
            $table->timestamp('became_parent_at')->after('has_sitter_profile')->nullable();
            $table->timestamp('became_sitter_at')->after('became_parent_at')->nullable();
        });

        DB::statement('UPDATE users SET has_parent_profile = true, became_parent_at = created_at WHERE email_verified_at IS NOT NULL');
        DB::statement('UPDATE users SET has_sitter_profile = true, became_sitter_at = created_at WHERE role = \'babysitter\' AND EXISTS (SELECT 1 FROM babysitter_profiles WHERE babysitter_profiles.user_id = users.id)');

        Schema::create('parent_profiles', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->json('preferences')->nullable();
            $table->json('children_info')->nullable();
            $table->json('emergency_contacts')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('parent_profiles');
        Schema::table('users', function (Blueprint $table): void {
            $table->dropColumn([
                'has_parent_profile',
                'has_sitter_profile',
                'became_parent_at',
                'became_sitter_at',
            ]);
        });
    }
};
