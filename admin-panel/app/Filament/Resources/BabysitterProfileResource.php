<?php

namespace App\Filament\Resources;

use App\Filament\Resources\BabysitterProfileResource\Pages;
use App\Filament\Resources\BabysitterProfileResource\RelationManagers;
use App\Models\BabysitterProfile;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class BabysitterProfileResource extends Resource
{
    protected static ?string $model = BabysitterProfile::class;

    protected static ?string $navigationIcon = 'heroicon-o-briefcase';
    protected static ?string $navigationGroup = 'User Management';
    protected static ?string $recordTitleAttribute = 'id';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('User')
                    ->icon('heroicon-o-user')
                    ->schema([
                        Forms\Components\Select::make('user_id')
                            ->relationship('user', 'name')
                            ->searchable()
                            ->required(),
                    ]),
                Forms\Components\Section::make('Pricing')
                    ->icon('heroicon-o-currency-dollar')
                    ->columns(2)
                    ->schema([
                        Forms\Components\TextInput::make('hourly_rate')
                            ->required()
                            ->numeric()
                            ->prefix('$')
                            ->default(0.00),
                        Forms\Components\TextInput::make('extra_child_fee')
                            ->required()
                            ->numeric()
                            ->prefix('$')
                            ->default(0.00),
                        Forms\Components\TextInput::make('extra_child_rate')
                            ->required()
                            ->numeric()
                            ->prefix('$')
                            ->default(0.00),
                        Forms\Components\TextInput::make('special_needs_rate')
                            ->required()
                            ->numeric()
                            ->prefix('$')
                            ->default(0.00),
                        Forms\Components\TextInput::make('total_earnings')
                            ->required()
                            ->numeric()
                            ->prefix('$')
                            ->default(0),
                    ]),
                Forms\Components\Section::make('Children')
                    ->icon('heroicon-o-users')
                    ->columns(2)
                    ->schema([
                        Forms\Components\TextInput::make('included_children')
                            ->required()
                            ->numeric()
                            ->default(1),
                        Forms\Components\TextInput::make('absolute_max_children')
                            ->numeric()
                            ->default(null),
                        Forms\Components\TextInput::make('base_children_count')
                            ->required()
                            ->numeric()
                            ->default(1),
                        Forms\Components\TextInput::make('max_children_count')
                            ->required()
                            ->numeric()
                            ->default(5),
                        Forms\Components\TextInput::make('extra_allowed_children')
                            ->required()
                            ->numeric()
                            ->default(2),
                    ]),
                Forms\Components\Section::make('Statistics')
                    ->icon('heroicon-o-chart-bar')
                    ->columns(3)
                    ->schema([
                        Forms\Components\TextInput::make('rating')
                            ->required()
                            ->numeric()
                            ->step(0.1)
                            ->default(0.00),
                        Forms\Components\TextInput::make('review_count')
                            ->required()
                            ->numeric()
                            ->default(0),
                        Forms\Components\TextInput::make('years_experience')
                            ->required()
                            ->numeric()
                            ->default(0),
                        Forms\Components\TextInput::make('completed_bookings')
                            ->required()
                            ->numeric()
                            ->default(0),
                        Forms\Components\TextInput::make('cancelled_bookings')
                            ->required()
                            ->numeric()
                            ->default(0),
                        Forms\Components\TextInput::make('view_count')
                            ->required()
                            ->numeric()
                            ->default(0),
                        Forms\Components\TextInput::make('follower_count')
                            ->required()
                            ->numeric()
                            ->default(0),
                        Forms\Components\TextInput::make('total_rejected')
                            ->required()
                            ->numeric()
                            ->default(0),
                    ]),
                Forms\Components\Section::make('Settings')
                    ->icon('heroicon-o-cog-6-tooth')
                    ->columns(2)
                    ->schema([
                        Forms\Components\Toggle::make('is_available')
                            ->required(),
                        Forms\Components\Toggle::make('offers_emergency')
                            ->required(),
                        Forms\Components\Toggle::make('offers_overnight')
                            ->required(),
                        Forms\Components\Select::make('cancellation_policy_id')
                            ->relationship('cancellationPolicy', 'name')
                            ->searchable()
                            ->default(null),
                    ]),
                Forms\Components\Section::make('Details')
                    ->icon('heroicon-o-document-text')
                    ->schema([
                        Forms\Components\Textarea::make('description')
                            ->columnSpanFull(),
                        Forms\Components\Textarea::make('categories')
                            ->columnSpanFull(),
                        Forms\Components\Textarea::make('certificates')
                            ->columnSpanFull(),
                        Forms\Components\Textarea::make('gallery_images')
                            ->columnSpanFull(),
                        Forms\Components\Textarea::make('availability')
                            ->columnSpanFull(),
                        Forms\Components\Textarea::make('bank_account')
                            ->columnSpanFull(),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('user.name')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('hourly_rate')
                    ->money('USD')
                    ->sortable(),
                Tables\Columns\TextColumn::make('is_available')
                    ->badge()
                    ->color(fn (bool $state): string => $state ? 'success' : 'gray')
                    ->formatStateUsing(fn (bool $state): string => $state ? 'Yes' : 'No'),
                Tables\Columns\TextColumn::make('rating')
                    ->numeric(2)
                    ->sortable(),
                Tables\Columns\TextColumn::make('completed_bookings')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('total_earnings')
                    ->money('USD')
                    ->sortable(),
                Tables\Columns\TextColumn::make('review_count')
                    ->numeric()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('cancellationPolicy.name')
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\IconColumn::make('offers_emergency')
                    ->boolean()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\IconColumn::make('offers_overnight')
                    ->boolean()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('years_experience')
                    ->numeric()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('included_children')
                    ->numeric()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('view_count')
                    ->numeric()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('updated_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\TernaryFilter::make('is_available')
                    ->label('Available'),
                Tables\Filters\Filter::make('rating')
                    ->form([
                        Forms\Components\TextInput::make('rating_from')
                            ->numeric()
                            ->label('Rating from'),
                        Forms\Components\TextInput::make('rating_until')
                            ->numeric()
                            ->label('Rating until'),
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return $query
                            ->when(
                                $data['rating_from'],
                                fn (Builder $query, $rating): Builder => $query->where('rating', '>=', $rating),
                            )
                            ->when(
                                $data['rating_until'],
                                fn (Builder $query, $rating): Builder => $query->where('rating', '<=', $rating),
                            );
                    }),
                Tables\Filters\Filter::make('hourly_rate')
                    ->form([
                        Forms\Components\TextInput::make('rate_from')
                            ->numeric()
                            ->label('Rate from'),
                        Forms\Components\TextInput::make('rate_until')
                            ->numeric()
                            ->label('Rate until'),
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return $query
                            ->when(
                                $data['rate_from'],
                                fn (Builder $query, $rate): Builder => $query->where('hourly_rate', '>=', $rate),
                            )
                            ->when(
                                $data['rate_until'],
                                fn (Builder $query, $rate): Builder => $query->where('hourly_rate', '<=', $rate),
                            );
                    }),
            ])
            ->actions([
                Tables\Actions\Action::make('Approve Verification')
                    ->icon('heroicon-o-check-badge')
                    ->color('success')
                    ->requiresConfirmation()
                    ->action(function (BabysitterProfile $record): void {
                        $record->user?->update(['verification_status' => 'verified']);
                        \App\Models\Notification::create([
                            'user_id' => $record->user_id,
                            'title' => 'Profile Verified!',
                            'body' => 'Congratulations! Your babysitter profile has been verified by admin.',
                            'type' => 'system',
                            'show_push' => true,
                            'show_in_app' => true,
                            'is_read' => false,
                        ]);
                        \Filament\Notifications\Notification::make()
                            ->title('Babysitter profile verified')
                            ->success()
                            ->send();
                    })
                    ->visible(fn (BabysitterProfile $record): bool => $record->user?->verification_status !== 'verified'),
                Tables\Actions\Action::make('Reject Verification')
                    ->icon('heroicon-o-x-circle')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->form([
                        Forms\Components\Textarea::make('rejection_reason')
                            ->label('Rejection Reason')
                            ->required(),
                    ])
                    ->action(function (BabysitterProfile $record, array $data): void {
                        $record->user?->update(['verification_status' => 'rejected']);
                        \App\Models\Notification::create([
                            'user_id' => $record->user_id,
                            'title' => 'Verification Updates Required',
                            'body' => 'Your profile verification was rejected. Reason: ' . $data['rejection_reason'],
                            'type' => 'alert',
                            'show_push' => true,
                            'show_in_app' => true,
                            'is_read' => false,
                        ]);
                        \Filament\Notifications\Notification::make()
                            ->title('Babysitter profile rejected')
                            ->warning()
                            ->send();
                    })
                    ->visible(fn (BabysitterProfile $record): bool => $record->user?->verification_status !== 'rejected'),
                Tables\Actions\Action::make('Adjust Earnings')
                    ->icon('heroicon-o-currency-dollar')
                    ->color('info')
                    ->requiresConfirmation()
                    ->form([
                        Forms\Components\TextInput::make('total_earnings')
                            ->label('New Total Earnings ($)')
                            ->numeric()
                            ->required(),
                    ])
                    ->action(function (BabysitterProfile $record, array $data): void {
                        $record->update(['total_earnings' => $data['total_earnings']]);
                        \Filament\Notifications\Notification::make()
                            ->title('Earnings updated')
                            ->success()
                            ->send();
                    }),
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            RelationManagers\SitterReviewsRelationManager::class,
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListBabysitterProfiles::route('/'),
            'create' => Pages\CreateBabysitterProfile::route('/create'),
            'edit' => Pages\EditBabysitterProfile::route('/{record}/edit'),
        ];
    }
}
