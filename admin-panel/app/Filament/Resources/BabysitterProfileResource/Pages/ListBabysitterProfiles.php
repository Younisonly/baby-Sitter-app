<?php

namespace App\Filament\Resources\BabysitterProfileResource\Pages;

use App\Filament\Resources\BabysitterProfileResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListBabysitterProfiles extends ListRecords
{
    protected static string $resource = BabysitterProfileResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}
