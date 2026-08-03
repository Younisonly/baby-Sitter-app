<?php

namespace App\Providers;

use App\Models\Booking;
use App\Models\Conversation;
use App\Models\Message;
use App\Policies\BookingPolicy;
use App\Policies\ChatPolicy;
use App\Channels\AppDatabaseChannel;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        Gate::policy(Booking::class, BookingPolicy::class);
        Gate::policy(Conversation::class, ChatPolicy::class);
        Gate::policy(Message::class, ChatPolicy::class);

        Notification::extend('app_database', fn () => new AppDatabaseChannel);

        RateLimiter::for('api', function (Request $request) {
            if ($request->user() !== null) {
                return Limit::perMinute(100)->by($request->user()->id);
            }

            return Limit::perMinute(30)->by($request->ip());
        });

        RateLimiter::for('auth', function (Request $request) {
            return Limit::perMinute(5)->by($request->ip());
        });

        RateLimiter::for('favorites', function (Request $request) {
            return Limit::perMinute(20)->by($request->user()?->id ?: $request->ip());
        });

        RateLimiter::for('chat', function (Request $request) {
            return Limit::perMinute(100)->by($request->user()?->id ?: $request->ip());
        });

        RateLimiter::for('chat-send', function (Request $request) {
            return Limit::perMinute(30)->by($request->user()?->id ?: $request->ip());
        });

        RateLimiter::for('chat-image', function (Request $request) {
            return Limit::perMinute(10)->by($request->user()?->id ?: $request->ip());
        });

        RateLimiter::for('chat-voice', function (Request $request) {
            return Limit::perMinute(5)->by($request->user()?->id ?: $request->ip());
        });

        RateLimiter::for('chat-file', function (Request $request) {
            return Limit::perMinute(5)->by($request->user()?->id ?: $request->ip());
        });

        RateLimiter::for('chat-reaction', function (Request $request) {
            return Limit::perMinute(20)->by($request->user()?->id ?: $request->ip());
        });

        RateLimiter::for('chat-search', function (Request $request) {
            return Limit::perMinute(10)->by($request->user()?->id ?: $request->ip());
        });

        RateLimiter::for('heartbeat', function (Request $request) {
            return Limit::perMinute(5)->by($request->user()?->id ?: $request->ip());
        });

        RateLimiter::for('uploads', function (Request $request) {
            return Limit::perMinute(5)->by($request->user()?->id ?: $request->ip());
        });

        RateLimiter::for('bookings', function (Request $request) {
            return Limit::perMinute(10)->by($request->user()?->id ?: $request->ip());
        });

        RateLimiter::for('sitter-bookings', function (Request $request) {
            return Limit::perMinute(30)->by($request->user()?->id ?: $request->ip());
        });

        RateLimiter::for('booking-actions', function (Request $request) {
            return Limit::perMinute(15)->by($request->user()?->id ?: $request->ip());
        });

        RateLimiter::for('dashboard', function (Request $request) {
            return Limit::perMinute(30)->by($request->user()?->id ?: $request->ip());
        });

        RateLimiter::for('reschedule-requests', function (Request $request) {
            return Limit::perMinute(10)->by($request->user()?->id ?: $request->ip());
        });

        RateLimiter::for('reviews', function (Request $request) {
            return Limit::perMinute(10)->by($request->user()?->id ?: $request->ip());
        });

        RateLimiter::for('session', function (Request $request) {
            return Limit::perMinute(10)->by($request->user()?->id ?: $request->ip());
        });

        RateLimiter::for('tracking', function (Request $request) {
            return Limit::perMinute(60)->by($request->user()?->id ?: $request->ip());
        });
    }
}
