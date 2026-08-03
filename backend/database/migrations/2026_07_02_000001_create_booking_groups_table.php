<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('booking_groups', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->foreignId('customer_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('sitter_id')->constrained('users')->cascadeOnDelete();
            $table->unsignedInteger('total_amount')->default(0);
            $table->unsignedInteger('base_amount')->default(0);
            $table->unsignedInteger('extra_amount')->default(0);
            $table->unsignedInteger('special_needs_amount')->default(0);
            $table->unsignedSmallInteger('session_count')->default(1);
            $table->unsignedSmallInteger('completed_count')->default(0);
            $table->unsignedSmallInteger('cancelled_count')->default(0);
            $table->date('first_date');
            $table->date('last_date');
            $table->string('status', 30)->default('pending')->index();
            $table->decimal('rating', 3, 2)->nullable();
            $table->text('review')->nullable();
            $table->timestamps();

            $table->index(['customer_id', 'status']);
            $table->index(['sitter_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('booking_groups');
    }
};
