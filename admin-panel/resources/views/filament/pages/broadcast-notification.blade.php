<x-filament-panels::page>
    <form wire:submit="sendBroadcast">
        {{ $this->form }}

        <div class="mt-6 flex justify-end">
            <x-filament::button type="submit" size="lg" icon="heroicon-m-paper-airplane">
                Send Broadcast Notification
            </x-filament::button>
        </div>
    </form>
</x-filament-panels::page>
