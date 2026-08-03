<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('booking_tracking', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('booking_id')->constrained()->cascadeOnDelete();
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);
            $table->string('address', 255)->nullable();
            $table->decimal('speed', 5, 2)->nullable()->comment('meters per second');
            $table->unsignedTinyInteger('battery')->nullable()->comment('battery percentage');
            $table->timestamp('recorded_at')->useCurrent();

            $table->index('booking_id');
            $table->index(['booking_id', 'recorded_at']);
            $table->index(['booking_id', 'recorded_at', 'latitude', 'longitude'], 'idx_tracking_lookup');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('booking_tracking');
    }
};
