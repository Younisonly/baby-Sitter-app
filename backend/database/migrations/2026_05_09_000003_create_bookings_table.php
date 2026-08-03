<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('bookings', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('customer_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('sitter_id')->constrained('users')->cascadeOnDelete();
            $table->date('date')->index();
            $table->time('start_time');
            $table->time('end_time');
            $table->unsignedSmallInteger('duration');
            $table->decimal('total_amount', 10, 2);
            $table->enum('status', ['pending', 'confirmed', 'in_progress', 'completed', 'cancelled'])->default('pending')->index();
            $table->text('notes')->nullable();
            $table->string('address')->nullable();
            $table->unsignedTinyInteger('children_count')->nullable();
            $table->json('children_ages')->nullable();
            $table->text('special_instructions')->nullable();
            $table->text('cancellation_reason')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->decimal('rating', 3, 2)->nullable();
            $table->text('review')->nullable();
            $table->timestamps();

            $table->index(['sitter_id', 'date', 'start_time']);
            $table->index(['customer_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bookings');
    }
};
