<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::table('users')
            ->whereNull('last_seen_at')
            ->update(['last_seen_at' => DB::raw('created_at')]);
    }

    public function down(): void
    {
        DB::table('users')
            ->whereNotNull('last_seen_at')
            ->update(['last_seen_at' => null]);
    }
};
