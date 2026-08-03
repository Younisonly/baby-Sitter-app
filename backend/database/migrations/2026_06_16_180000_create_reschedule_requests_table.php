<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('reschedule_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('booking_id')->constrained()->cascadeOnDelete();
            $table->foreignId('requested_by_id')->constrained('users')->cascadeOnDelete();
            $table->string('status')->default('pending'); // pending, accepted, rejected, countered, cancelled
            $table->date('proposed_date');
            $table->time('proposed_start_time');
            $table->time('proposed_end_time');
            $table->text('reason')->nullable();
            $table->date('counter_date')->nullable();
            $table->time('counter_start_time')->nullable();
            $table->time('counter_end_time')->nullable();
            $table->text('counter_reason')->nullable();
            $table->timestamp('responded_at')->nullable();
            $table->timestamps();

            $table->index('booking_id');
            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reschedule_requests');
    }
};
