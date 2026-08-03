<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class SendBulkNotificationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;
    public int $backoff = 5;

    public function __construct(
        private readonly array $userIds,
        private readonly string $actionKey,
        private readonly array $replacements = [],
        private readonly ?string $deepLinkId = null,
    ) {}

    public function handle(\App\Services\NotificationService $notificationService): void
    {
        $notificationService->sendToMultipleUsers(
            $this->userIds,
            $this->actionKey,
            $this->replacements,
            $this->deepLinkId,
        );
    }
}
