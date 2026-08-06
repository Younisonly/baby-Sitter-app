<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class OtpMail extends Mailable
{
    use Queueable;
    use SerializesModels;

    public string $otp;

    public string $userName;

    public function __construct(string $otp, string $userName = '')
    {
        $this->otp = $otp;
        $this->userName = $userName ?: __('auth.otp_greeting_default');
    }

    public function build(): Mailable
    {
        return $this
            ->subject(__('auth.otp_email_subject'))
            ->view('emails.otp');
    }
}
