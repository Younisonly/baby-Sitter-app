<?php

namespace App\Filament\Resources\UserResource\RelationManagers;

use App\Models\Booking;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class UserBookingsRelationManager extends RelationManager
{
    protected static string $relationship = 'customerBookings';

    protected static ?string $recordTitleAttribute = 'booking_number';

    public static function getTitle($ownerRecord, string $pageClass): string
    {
        return __('admin.navigation.resources.Bookings');
    }

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('booking_number')
            ->columns([
                Tables\Columns\TextColumn::make('booking_number')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('sitter.name')
                    ->label(__('admin.forms.fields.Sitter'))
                    ->searchable(),
                Tables\Columns\TextColumn::make('date')
                    ->date()
                    ->sortable(),
                Tables\Columns\TextColumn::make('total_amount')
                    ->money('USD')
                    ->sortable(),
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->colors([
                        'warning' => 'pending',
                        'info' => 'confirmed',
                        'primary' => 'in_progress',
                        'success' => 'completed',
                        'danger' => 'cancelled',
                        'gray' => 'rejected',
                    ])
                    ->formatStateUsing(fn (string $state): string => ucfirst(str_replace('_', ' ', $state))),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        'pending' => 'Pending',
                        'confirmed' => 'Confirmed',
                        'in_progress' => 'In Progress',
                        'completed' => 'Completed',
                        'cancelled' => 'Cancelled',
                    ]),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
            ]);
    }
}
