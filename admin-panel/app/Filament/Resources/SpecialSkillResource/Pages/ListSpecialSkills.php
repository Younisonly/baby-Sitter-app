<?php

namespace App\Filament\Resources\SpecialSkillResource\Pages;

use App\Filament\Resources\SpecialSkillResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListSpecialSkills extends ListRecords
{
    protected static string $resource = SpecialSkillResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}
