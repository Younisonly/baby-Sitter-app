<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        DB::table('babysitter_profiles')
            ->where('follower_count', '<', 0)
            ->update(['follower_count' => 0]);

        DB::table('babysitter_profiles')
            ->where('view_count', '<', 0)
            ->update(['view_count' => 0]);

        DB::table('babysitter_profiles')
            ->where('total_rejected', '<', 0)
            ->update(['total_rejected' => 0]);
    }

    public function down(): void
    {
    }
};
