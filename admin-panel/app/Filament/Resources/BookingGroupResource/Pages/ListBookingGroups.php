<?php

namespace App\Filament\Resources\BookingGroupResource\Pages;

use App\Filament\Resources\BookingGroupResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListBookingGroups extends ListRecords
{
    protected static string $resource = BookingGroupResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}
