<?php

namespace App\Filament\Resources\SpecialSkillResource\Pages;

use App\Filament\Resources\SpecialSkillResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditSpecialSkill extends EditRecord
{
    protected static string $resource = SpecialSkillResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make(),
        ];
    }
}
