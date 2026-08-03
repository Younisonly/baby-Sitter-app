<?php

namespace App\Jobs;

use App\Models\UserDevice;
use App\Services\FcmPushService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class SendPushNotificationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 5;

    public function __construct(
        private readonly UserDevice $device,
        private readonly string $title,
        private readonly string $body,
        private readonly ?string $deepLinkType = null,
        private readonly ?string $deepLinkId = null,
        private readonly ?int $notificationId = null,
        private readonly ?string $actionKey = null,
        private readonly array $replacements = [],
    ) {}

    public function handle(FcmPushService $fcmPushService): void
    {
        $fcmPushService->send(
            $this->device,
            $this->title,
            $this->body,
            $this->deepLinkType,
            $this->deepLinkId,
            $this->notificationId,
            $this->actionKey,
            $this->replacements,
        );
    }
}
