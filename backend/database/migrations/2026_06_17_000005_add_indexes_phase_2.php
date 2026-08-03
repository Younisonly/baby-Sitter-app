<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('message_reactions', function (Blueprint $table): void {
            $table->index('user_id', 'idx_message_reactions_user_id');
        });

        Schema::table('message_attachments', function (Blueprint $table): void {
            $table->index('message_id', 'idx_message_attachments_message_id');
        });

        Schema::table('messages', function (Blueprint $table): void {
            $table->index('reply_to_id', 'idx_messages_reply_to_id');
        });

        Schema::table('cities', function (Blueprint $table): void {
            $table->index('country_id', 'idx_cities_country_id');
        });

        Schema::table('booking_status_histories', function (Blueprint $table): void {
            $table->index('changed_by_id', 'idx_booking_status_histories_changed_by_id');
        });

        Schema::table('timeline_events', function (Blueprint $table): void {
            $table->index('actor_id', 'idx_timeline_events_actor_id');
        });

        Schema::table('users', function (Blueprint $table): void {
            $table->index('email_verified_at', 'idx_users_email_verified_at');
        });

        Schema::table('conversations', function (Blueprint $table): void {
            $table->index('last_sender_id', 'idx_conversations_last_sender_id');
        });

        Schema::table('babysitter_profiles', function (Blueprint $table): void {
            $table->index('cancellation_policy_id', 'idx_babysitter_profiles_cancellation_policy_id');
        });

        Schema::table('users', function (Blueprint $table): void {
            $table->index('is_suspended', 'idx_users_is_suspended');
        });

        Schema::table('bookings', function (Blueprint $table): void {
            $table->index('rescheduled_from_id', 'idx_bookings_rescheduled_from_id');
        });
    }

    public function down(): void
    {
        Schema::table('message_reactions', function (Blueprint $table): void {
            $table->dropIndex('idx_message_reactions_user_id');
        });

        Schema::table('message_attachments', function (Blueprint $table): void {
            $table->dropIndex('idx_message_attachments_message_id');
        });

        Schema::table('messages', function (Blueprint $table): void {
            $table->dropIndex('idx_messages_reply_to_id');
        });

        Schema::table('cities', function (Blueprint $table): void {
            $table->dropIndex('idx_cities_country_id');
        });

        Schema::table('booking_status_histories', function (Blueprint $table): void {
            $table->dropIndex('idx_booking_status_histories_changed_by_id');
        });

        Schema::table('timeline_events', function (Blueprint $table): void {
            $table->dropIndex('idx_timeline_events_actor_id');
        });

        Schema::table('users', function (Blueprint $table): void {
            $table->dropIndex('idx_users_email_verified_at');
            $table->dropIndex('idx_users_is_suspended');
        });

        Schema::table('conversations', function (Blueprint $table): void {
            $table->dropIndex('idx_conversations_last_sender_id');
        });

        Schema::table('babysitter_profiles', function (Blueprint $table): void {
            $table->dropIndex('idx_babysitter_profiles_cancellation_policy_id');
        });

        Schema::table('bookings', function (Blueprint $table): void {
            $table->dropIndex('idx_bookings_rescheduled_from_id');
        });
    }
};
