<?php

namespace App\Filament\Resources;

use App\Filament\Resources\BookingResource\Pages;
use App\Filament\Resources\BookingResource\RelationManagers;
use App\Models\Booking;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class BookingResource extends Resource
{
    protected static ?string $model = Booking::class;

    protected static ?string $navigationIcon = 'heroicon-o-calendar-days';
    protected static ?string $recordTitleAttribute = 'booking_number';

    public static function getNavigationGroup(): ?string
    {
        return __('admin.navigation.groups.Bookings');
    }

    public static function getPluralModelLabel(): string
    {
        return __('admin.navigation.resources.Bookings');
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Booking Details')
                    ->icon('heroicon-o-receipt-percent')
                    ->columns(2)
                    ->schema([
                        Forms\Components\TextInput::make('booking_number')
                            ->required()
                            ->maxLength(50),
                        Forms\Components\TextInput::make('booking_group_id')
                            ->maxLength(36)
                            ->default(null),
                        Forms\Components\Select::make('status')
                            ->options([
                                'pending' => 'Pending',
                                'confirmed' => 'Confirmed',
                                'in_progress' => 'In Progress',
                                'completed' => 'Completed',
                                'cancelled' => 'Cancelled',
                                'rejected' => 'Rejected',
                                'expired' => 'Expired',
                            ])
                            ->required(),
                        Forms\Components\Select::make('session_status')
                            ->options([
                                'pending' => 'Pending',
                                'pending_start' => 'Pending Start',
                                'in_progress' => 'In Progress',
                                'completed' => 'Completed',
                                'cancelled' => 'Cancelled',
                            ])
                            ->required()
                            ->default('pending'),
                    ]),
                Forms\Components\Section::make('Customer & Sitter')
                    ->icon('heroicon-o-user-group')
                    ->columns(2)
                    ->schema([
                        Forms\Components\Select::make('customer_id')
                            ->relationship('customer', 'name')
                            ->searchable()
                            ->required(),
                        Forms\Components\Select::make('sitter_id')
                            ->relationship('sitter', 'name')
                            ->searchable()
                            ->required(),
                    ]),
                Forms\Components\Section::make('Schedule')
                    ->icon('heroicon-o-clock')
                    ->columns(2)
                    ->schema([
                        Forms\Components\DatePicker::make('date')
                            ->required(),
                        Forms\Components\TextInput::make('start_time')
                            ->required(),
                        Forms\Components\TextInput::make('end_time')
                            ->required(),
                        Forms\Components\TextInput::make('duration')
                            ->required()
                            ->numeric()
                            ->suffix('hours'),
                        Forms\Components\TextInput::make('expected_hours')
                            ->required()
                            ->numeric()
                            ->default(0.00),
                        Forms\Components\TextInput::make('actual_hours')
                            ->required()
                            ->numeric()
                            ->default(0.00),
                        Forms\Components\TextInput::make('overtime_minutes')
                            ->required()
                            ->numeric()
                            ->default(0),
                        Forms\Components\TextInput::make('overtime_cost')
                            ->required()
                            ->numeric()
                            ->prefix('$')
                            ->default(0),
                        Forms\Components\TextInput::make('waiting_minutes')
                            ->required()
                            ->numeric()
                            ->default(0),
                        Forms\Components\TextInput::make('waiting_cost')
                            ->required()
                            ->numeric()
                            ->prefix('$')
                            ->default(0),
                    ]),
                Forms\Components\Section::make('Pricing')
                    ->icon('heroicon-o-currency-dollar')
                    ->columns(2)
                    ->schema([
                        Forms\Components\TextInput::make('total_amount')
                            ->required()
                            ->numeric()
                            ->prefix('$'),
                        Forms\Components\TextInput::make('base_amount')
                            ->required()
                            ->numeric()
                            ->prefix('$')
                            ->default(0),
                        Forms\Components\TextInput::make('extra_amount')
                            ->required()
                            ->numeric()
                            ->prefix('$')
                            ->default(0),
                        Forms\Components\TextInput::make('special_needs_amount')
                            ->required()
                            ->numeric()
                            ->prefix('$')
                            ->default(0),
                    ]),
                Forms\Components\Section::make('Session')
                    ->icon('heroicon-o-play')
                    ->columns(2)
                    ->schema([
                        Forms\Components\Toggle::make('is_day_completed'),
                        Forms\Components\DateTimePicker::make('day_completed_at'),
                        Forms\Components\DateTimePicker::make('session_started_at'),
                        Forms\Components\DateTimePicker::make('session_ended_at'),
                        Forms\Components\DateTimePicker::make('gps_started_at'),
                        Forms\Components\DateTimePicker::make('gps_ended_at'),
                        Forms\Components\TextInput::make('address')
                            ->maxLength(255)
                            ->default(null),
                        Forms\Components\TextInput::make('children_count')
                            ->numeric()
                            ->default(null),
                        Forms\Components\TextInput::make('special_needs_count')
                            ->required()
                            ->numeric()
                            ->default(0),
                        Forms\Components\Textarea::make('session_notes')
                            ->columnSpanFull(),
                        Forms\Components\Textarea::make('children_ages')
                            ->columnSpanFull(),
                        Forms\Components\Textarea::make('children_names')
                            ->columnSpanFull(),
                        Forms\Components\Textarea::make('special_instructions')
                            ->columnSpanFull(),
                        Forms\Components\Textarea::make('schedule_events')
                            ->columnSpanFull(),
                    ]),
                Forms\Components\Section::make('Review')
                    ->icon('heroicon-o-star')
                    ->columns(2)
                    ->schema([
                        Forms\Components\TextInput::make('rating')
                            ->numeric()
                            ->step(0.5)
                            ->minValue(1)
                            ->maxValue(5)
                            ->default(null),
                        Forms\Components\Textarea::make('review')
                            ->columnSpanFull(),
                        Forms\Components\Textarea::make('reply')
                            ->columnSpanFull(),
                        Forms\Components\DateTimePicker::make('replied_at'),
                        Forms\Components\TextInput::make('helpful_count')
                            ->required()
                            ->numeric()
                            ->default(0),
                    ]),
                Forms\Components\Section::make('Timestamps')
                    ->icon('heroicon-o-clock')
                    ->columns(2)
                    ->schema([
                        Forms\Components\DateTimePicker::make('confirmation_deadline'),
                        Forms\Components\DateTimePicker::make('confirmed_at'),
                        Forms\Components\DateTimePicker::make('in_progress_at'),
                        Forms\Components\DateTimePicker::make('completed_at'),
                        Forms\Components\DateTimePicker::make('cancelled_at'),
                        Forms\Components\DateTimePicker::make('rejected_at'),
                        Forms\Components\DateTimePicker::make('expired_at'),
                        Forms\Components\DateTimePicker::make('reported_at'),
                        Forms\Components\Select::make('rescheduled_from_id')
                            ->relationship('rescheduledFrom', 'id')
                            ->default(null),
                    ]),
                Forms\Components\Section::make('Notes & History')
                    ->icon('heroicon-o-document-text')
                    ->schema([
                        Forms\Components\Textarea::make('notes')
                            ->columnSpanFull(),
                        Forms\Components\Textarea::make('cancellation_reason')
                            ->columnSpanFull(),
                        Forms\Components\Textarea::make('rejection_reason')
                            ->columnSpanFull(),
                        Forms\Components\Textarea::make('status_history')
                            ->columnSpanFull(),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('booking_number')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('customer.name')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('sitter.name')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('date')
                    ->date()
                    ->sortable(),
                Tables\Columns\TextColumn::make('start_time')
                    ->sortable(),
                Tables\Columns\TextColumn::make('end_time')
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
                        'dark' => 'expired',
                    ])
                    ->formatStateUsing(fn (string $state): string => str_replace('_', ' ', ucfirst($state))),
                Tables\Columns\TextColumn::make('total_amount')
                    ->money('USD')
                    ->sortable(),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable(),
                Tables\Columns\TextColumn::make('session_status')
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('duration')
                    ->numeric()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('address')
                    ->searchable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('children_count')
                    ->numeric()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('rating')
                    ->numeric()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('updated_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->multiple()
                    ->options([
                        'pending' => 'Pending',
                        'confirmed' => 'Confirmed',
                        'in_progress' => 'In Progress',
                        'completed' => 'Completed',
                        'cancelled' => 'Cancelled',
                        'rejected' => 'Rejected',
                        'expired' => 'Expired',
                    ]),
                Tables\Filters\Filter::make('date')
                    ->form([
                        Forms\Components\DatePicker::make('date_from'),
                        Forms\Components\DatePicker::make('date_until'),
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return $query
                            ->when(
                                $data['date_from'],
                                fn (Builder $query, $date): Builder => $query->whereDate('date', '>=', $date),
                            )
                            ->when(
                                $data['date_until'],
                                fn (Builder $query, $date): Builder => $query->whereDate('date', '<=', $date),
                            );
                    }),
                Tables\Filters\SelectFilter::make('customer_id')
                    ->label('Customer')
                    ->relationship('customer', 'name')
                    ->searchable(),
                Tables\Filters\SelectFilter::make('sitter_id')
                    ->label('Sitter')
                    ->relationship('sitter', 'name')
                    ->searchable(),
            ])
            ->actions([
                Tables\Actions\Action::make('Force Confirm')
                    ->icon('heroicon-o-check-badge')
                    ->color('info')
                    ->requiresConfirmation()
                    ->action(function (Booking $record): void {
                        $record->update(['status' => 'confirmed', 'confirmed_at' => now()]);
                    })
                    ->visible(fn (Booking $record): bool => $record->status === 'pending'),
                Tables\Actions\Action::make('Force Complete')
                    ->icon('heroicon-o-check-circle')
                    ->color('success')
                    ->requiresConfirmation()
                    ->action(function (Booking $record): void {
                        $record->update(['status' => 'completed', 'completed_at' => now()]);
                    })
                    ->visible(fn (Booking $record): bool => in_array($record->status, ['confirmed', 'in_progress'])),
                Tables\Actions\Action::make('Force Cancel')
                    ->icon('heroicon-o-x-circle')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->form([
                        Forms\Components\Textarea::make('cancellation_reason')
                            ->label('Cancellation Reason')
                            ->required(),
                    ])
                    ->action(function (Booking $record, array $data): void {
                        $record->update([
                            'status' => 'cancelled',
                            'cancellation_reason' => $data['cancellation_reason'],
                            'cancelled_at' => now(),
                        ]);
                    }),
                Tables\Actions\Action::make('Reassign Sitter')
                    ->icon('heroicon-o-user-plus')
                    ->color('warning')
                    ->requiresConfirmation()
                    ->form([
                        Forms\Components\Select::make('sitter_id')
                            ->label('New Babysitter')
                            ->relationship('sitter', 'name', fn ($query) => $query->where('role', 'babysitter')->where('verification_status', 'verified'))
                            ->searchable()
                            ->required(),
                    ])
                    ->action(function (Booking $record, array $data): void {
                        $record->update(['sitter_id' => $data['sitter_id']]);
                        \Filament\Notifications\Notification::make()
                            ->title('Sitter reassigned successfully')
                            ->success()
                            ->send();
                    })
                    ->visible(fn (Booking $record): bool => in_array($record->status, ['pending', 'confirmed'])),
                Tables\Actions\Action::make('Adjust Pricing')
                    ->icon('heroicon-o-adjustments-horizontal')
                    ->color('info')
                    ->form([
                        Forms\Components\TextInput::make('base_amount')
                            ->numeric()
                            ->prefix('$'),
                        Forms\Components\TextInput::make('overtime_cost')
                            ->numeric()
                            ->prefix('$'),
                        Forms\Components\TextInput::make('waiting_cost')
                            ->numeric()
                            ->prefix('$'),
                        Forms\Components\TextInput::make('total_amount')
                            ->numeric()
                            ->prefix('$')
                            ->required(),
                    ])
                    ->action(function (Booking $record, array $data): void {
                        $record->update(array_filter($data, fn ($val) => !is_null($val)));
                        \Filament\Notifications\Notification::make()
                            ->title('Booking pricing updated')
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
            RelationManagers\StatusHistoryRelationManager::class,
            RelationManagers\BookingTrackingRelationManager::class,
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListBookings::route('/'),
            'create' => Pages\CreateBooking::route('/create'),
            'edit' => Pages\EditBooking::route('/{record}/edit'),
        ];
    }
}
