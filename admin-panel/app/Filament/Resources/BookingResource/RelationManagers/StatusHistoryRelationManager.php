<?php

namespace App\Filament\Resources\BookingResource\RelationManagers;

use App\Models\BookingStatusHistory;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;

class StatusHistoryRelationManager extends RelationManager
{
    protected static string $relationship = 'statusHistories';

    protected static ?string $recordTitleAttribute = 'id';

    public static function getTitle($ownerRecord, string $pageClass): string
    {
        return __('admin.forms.fields.Status History');
    }

    public function table(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('from_status')
                    ->badge()
                    ->formatStateUsing(fn (?string $state): string => $state ? ucfirst(str_replace('_', ' ', $state)) : 'None'),
                Tables\Columns\TextColumn::make('to_status')
                    ->badge()
                    ->color('primary')
                    ->formatStateUsing(fn (string $state): string => ucfirst(str_replace('_', ' ', $state))),
                Tables\Columns\TextColumn::make('changedBy.name')
                    ->label(__('admin.forms.fields.Last Sender'))
                    ->default('System / User'),
                Tables\Columns\TextColumn::make('reason')
                    ->label(__('admin.forms.fields.Reason'))
                    ->wrap(),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable(),
            ])
            ->paginated(false);
    }
}
