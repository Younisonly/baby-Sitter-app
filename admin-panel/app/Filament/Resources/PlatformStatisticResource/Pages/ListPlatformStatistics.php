<?php

namespace App\Filament\Resources\PlatformStatisticResource\Pages;

use App\Filament\Resources\PlatformStatisticResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListPlatformStatistics extends ListRecords
{
    protected static string $resource = PlatformStatisticResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}