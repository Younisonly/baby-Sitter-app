<?php

namespace App\Filament\Resources\UserResource\RelationManagers;

use App\Models\UserDevice;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;

class UserDevicesRelationManager extends RelationManager
{
    protected static string $relationship = 'devices';

    protected static ?string $recordTitleAttribute = 'device_name';

    public static function getTitle($ownerRecord, string $pageClass): string
    {
        return 'Registered Devices & Push Tokens';
    }

    public function table(Table $table): Table
    {
        return $table
            ->defaultSort('last_active_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('device_name')
                    ->label('Device Name')
                    ->searchable()
                    ->default('Unknown Device'),
                Tables\Columns\TextColumn::make('platform')
                    ->badge()
                    ->colors([
                        'info' => 'android',
                        'primary' => 'ios',
                    ])
                    ->formatStateUsing(fn (?string $state): string => strtoupper($state ?? 'OTHER')),
                Tables\Columns\TextColumn::make('app_version')
                    ->label('App Version'),
                Tables\Columns\TextColumn::make('os_version')
                    ->label('OS Version'),
                Tables\Columns\IconColumn::make('is_active')
                    ->label('Active')
                    ->boolean(),
                Tables\Columns\TextColumn::make('last_active_at')
                    ->label('Last Active')
                    ->dateTime()
                    ->sortable(),
            ])
            ->actions([
                Tables\Actions\Action::make('Toggle Access')
                    ->icon('heroicon-o-power')
                    ->color('warning')
                    ->requiresConfirmation()
                    ->action(fn (UserDevice $record) => $record->update(['is_active' => !$record->is_active])),
                Tables\Actions\DeleteAction::make(),
            ]);
    }
}
