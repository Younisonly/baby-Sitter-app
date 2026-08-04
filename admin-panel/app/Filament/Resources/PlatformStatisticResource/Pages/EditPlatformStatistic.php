<?php

namespace App\Filament\Resources\PlatformStatisticResource\Pages;

use App\Filament\Resources\PlatformStatisticResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditPlatformStatistic extends EditRecord
{
    protected static string $resource = PlatformStatisticResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make(),
        ];
    }
}