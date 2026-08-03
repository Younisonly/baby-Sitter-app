<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('babysitter_profiles', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->decimal('hourly_rate', 8, 2)->default(0);
            $table->decimal('rating', 3, 2)->default(0);
            $table->unsignedInteger('review_count')->default(0);
            $table->unsignedTinyInteger('years_experience')->default(0);
            $table->text('description')->nullable();
            $table->json('categories')->nullable();
            $table->json('certificates')->nullable();
            $table->json('gallery_images')->nullable();
            $table->unsignedInteger('completed_bookings')->default(0);
            $table->unsignedInteger('cancelled_bookings')->default(0);
            $table->unsignedInteger('total_earnings')->default(0);
            $table->boolean('is_available')->default(true)->index();
            $table->json('availability')->nullable();
            $table->string('bank_account')->nullable();
            $table->timestamps();

            $table->index(['is_available', 'rating']);
            $table->index(['hourly_rate']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('babysitter_profiles');
    }
};
