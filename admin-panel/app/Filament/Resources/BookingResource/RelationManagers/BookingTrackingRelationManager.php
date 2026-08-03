<?php

namespace App\Filament\Resources\BookingResource\RelationManagers;

use App\Models\BookingTracking;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;

class BookingTrackingRelationManager extends RelationManager
{
    protected static string $relationship = 'trackingLogs';

    protected static ?string $recordTitleAttribute = 'id';

    public static function getTitle($ownerRecord, string $pageClass): string
    {
        return 'GPS Live Session Tracking';
    }

    public function table(Table $table): Table
    {
        return $table
            ->defaultSort('recorded_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('recorded_at')
                    ->label('Recorded At')
                    ->dateTime()
                    ->sortable(),
                Tables\Columns\TextColumn::make('address')
                    ->label('Location Address')
                    ->searchable()
                    ->wrap(),
                Tables\Columns\TextColumn::make('latitude')
                    ->label('Latitude'),
                Tables\Columns\TextColumn::make('longitude')
                    ->label('Longitude'),
                Tables\Columns\TextColumn::make('battery')
                    ->label('Sitter Device Battery')
                    ->suffix('%')
                    ->icon('heroicon-o-battery-50')
                    ->sortable(),
                Tables\Columns\TextColumn::make('speed')
                    ->label('Speed')
                    ->suffix(' km/h'),
            ])
            ->paginated([10, 25, 50]);
    }
}
