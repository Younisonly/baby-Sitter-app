<?php

namespace App\Filament\Resources\BabysitterProfileResource\Pages;

use App\Filament\Resources\BabysitterProfileResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditBabysitterProfile extends EditRecord
{
    protected static string $resource = BabysitterProfileResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make(),
        ];
    }
}
