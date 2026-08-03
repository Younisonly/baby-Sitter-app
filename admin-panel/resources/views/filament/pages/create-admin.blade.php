<x-filament-panels::page>
    <form wire:submit="create">
        {{ $this->form }}

        <div class="mt-6 flex justify-end">
            <x-filament::button type="submit" size="lg" icon="heroicon-m-user-plus">
                {{ __('admin.pages.create_admin.submit') }}
            </x-filament::button>
        </div>
    </form>
</x-filament-panels::page>