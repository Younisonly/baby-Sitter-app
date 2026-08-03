<?php

namespace App\Jobs;

use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class SendNotificationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 3;

    public function __construct(
        private readonly int $userId,
        private readonly string $actionKey,
        private readonly array $replacements = [],
        private readonly ?string $deepLinkId = null,
        private readonly ?string $image = null,
    ) {}

    public function handle(NotificationService $notificationService): void
    {
        $user = User::find($this->userId);

        if (!$user) {
            return;
        }

        $notificationService->send(
            $user,
            $this->actionKey,
            $this->replacements,
            $this->deepLinkId,
            $this->image,
        );
    }
}
