<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement('ALTER TABLE babysitter_profiles MODIFY bank_account TEXT NULL');
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE babysitter_profiles MODIFY bank_account VARCHAR(255) NULL');
    }
};
