<?php

namespace App\Filament\Resources\BabysitterProfileResource\RelationManagers;

use App\Models\Booking;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class SitterReviewsRelationManager extends RelationManager
{
    protected static string $relationship = 'bookings';

    protected static ?string $recordTitleAttribute = 'review';

    public static function getTitle($ownerRecord, string $pageClass): string
    {
        return 'Customer Reviews & Feedback';
    }

    public function table(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query) => $query->whereNotNull('rating'))
            ->defaultSort('completed_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('customer.name')
                    ->label('Parent Name')
                    ->searchable(),
                Tables\Columns\TextColumn::make('rating')
                    ->label('Rating')
                    ->numeric(1)
                    ->icon('heroicon-s-star')
                    ->iconColor('warning')
                    ->sortable(),
                Tables\Columns\TextColumn::make('review')
                    ->label('Review Text')
                    ->wrap()
                    ->searchable(),
                Tables\Columns\TextColumn::make('reply')
                    ->label('Sitter Reply')
                    ->wrap()
                    ->placeholder('No reply yet'),
                Tables\Columns\TextColumn::make('created_at')
                    ->label('Date')
                    ->dateTime()
                    ->sortable(),
            ])
            ->actions([
                Tables\Actions\EditAction::make()
                    ->label('Moderate Review')
                    ->form([
                        Forms\Components\TextInput::make('rating')
                            ->numeric()
                            ->step(0.5)
                            ->minValue(1)
                            ->maxValue(5)
                            ->required(),
                        Forms\Components\Textarea::make('review')
                            ->label('Parent Review Content')
                            ->required(),
                        Forms\Components\Textarea::make('reply')
                            ->label('Sitter Reply Content'),
                    ]),
                Tables\Actions\Action::make('Remove Review')
                    ->icon('heroicon-o-trash')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->action(fn (Booking $record) => $record->update(['rating' => null, 'review' => null, 'reply' => null])),
            ]);
    }
}
