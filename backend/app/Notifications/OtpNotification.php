<?php

namespace App\Notifications;

use App\Mail\OtpMail;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Notification;

class OtpNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(private string $otp)
    {
    }

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): OtpMail
    {
        app()->setLocale($notifiable->preferred_language ?? 'en');

        $userName = trim((string) ($notifiable->name ?? ''));

        return (new OtpMail($this->otp, $userName))->to($notifiable->email);
    }
}
