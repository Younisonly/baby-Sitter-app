<?php

use App\Models\BookingGroup;
use App\Services\BookingGroupService;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    public function up(): void
    {
        $service = app(BookingGroupService::class);

        BookingGroup::whereIn('status', ['partially_cancelled'])
            ->orWhere(function ($q) {
                $q->whereNotIn('status', [
                    'pending', 'confirmed', 'in_progress', 'completed',
                    'cancelled', 'rejected', 'expired',
                ]);
            })
            ->get()
            ->each(fn(BookingGroup $group) => $service->syncFromGroup($group));
    }

    public function down(): void
    {
    }
};
