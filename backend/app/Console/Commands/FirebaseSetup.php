<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

final class FirebaseSetup extends Command
{
    protected $signature = 'firebase:setup {--paste : Paste the service account JSON interactively}';
    protected $description = 'Configure Firebase service account for push notifications';

    public function handle(): int
    {
        $path = storage_path('app/firebase-service-account.json');

        if (file_exists($path)) {
            $this->info('Firebase service account found at: ' . $path);
            return self::SUCCESS;
        }

        $envJson = env('FIREBASE_SERVICE_ACCOUNT_JSON');
        if (!empty($envJson)) {
            $this->info('Firebase service account found in FIREBASE_SERVICE_ACCOUNT_JSON env var.');
            return self::SUCCESS;
        }

        if ($this->option('paste')) {
            return $this->pasteJson($path);
        }

        $this->warn('Firebase service account NOT found.');
        $this->newLine();
        $this->info('You have two options:');
        $this->newLine();
        $this->info('Option 1: Download from Firebase Console');
        $this->line('  1. Go to https://console.firebase.google.com/project/babysitter-29120/settings/serviceaccounts/adminsdk');
        $this->line('  2. Click "Generate new private key"');
        $this->line('  3. Save the downloaded JSON to:');
        $this->line('     ' . $path);
        $this->newLine();
        $this->info('Option 2: Use environment variable');
        $this->line('  Base64-encode the JSON and add to your .env:');
        $this->line('  FIREBASE_SERVICE_ACCOUNT_JSON=base64_encoded_string');
        $this->newLine();
        $this->info('  Then run: php artisan firebase:setup');
        $this->newLine();
        $this->info('  Quick encode: base64 -w0 firebase-service-account.json');
        $this->newLine();
        $this->warn('Until configured, push notifications will not be delivered.');

        return self::SUCCESS;
    }

    private function pasteJson(string $path): int
    {
        $this->info('Paste the contents of your firebase-service-account.json below.');
        $this->line('Press Ctrl+D (or Cmd+D) on a new line when done.');

        $lines = [];
        while ($line = fgets(STDIN)) {
            $lines[] = rtrim($line, PHP_EOL);
        }

        $json = implode("\n", $lines);
        $decoded = json_decode($json);

        if ($decoded === null) {
            $this->error('Invalid JSON. Please check the content and try again.');
            return self::FAILURE;
        }

        file_put_contents($path, $json);
        $this->info('Service account saved to: ' . $path);

        return self::SUCCESS;
    }
}
