<?php

namespace App\Filament\Resources;

use App\Filament\Resources\RescheduleRequestResource\Pages;
use App\Filament\Resources\RescheduleRequestResource\RelationManagers;
use App\Models\RescheduleRequest;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class RescheduleRequestResource extends Resource
{
    protected static ?string $model = RescheduleRequest::class;

    protected static ?string $navigationIcon = 'heroicon-o-arrow-path';
    protected static ?string $recordTitleAttribute = 'id';

    public static function getNavigationGroup(): ?string
    {
        return __('admin.navigation.groups.Bookings');
    }

    public static function getModelLabel(): string
    {
        return __('admin.navigation.resources.Reschedule Requests');
    }

    public static function getPluralModelLabel(): string
    {
        return __('admin.navigation.resources.Reschedule Requests');
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make(__('admin.forms.sections.Details'))
                    ->columns(2)
                    ->schema([
                        Forms\Components\Select::make('booking_id')
                            ->relationship('booking', 'booking_number')
                            ->searchable()
                            ->required(),
                        Forms\Components\Select::make('requested_by_id')
                            ->relationship('requester', 'name')
                            ->searchable()
                            ->required()
                            ->label(__('admin.forms.fields.Requested By')),
                        Forms\Components\Select::make('status')
                            ->options([
                                'pending' => 'Pending',
                                'approved' => 'Approved',
                                'declined' => 'Declined',
                                'countered' => 'Countered',
                            ])
                            ->required(),
                    ]),
                Forms\Components\Section::make(__('admin.forms.sections.Proposed Schedule'))
                    ->icon('heroicon-o-calendar')
                    ->columns(2)
                    ->schema([
                        Forms\Components\DatePicker::make('proposed_date')
                            ->required(),
                        Forms\Components\TextInput::make('proposed_start_time')
                            ->required(),
                        Forms\Components\TextInput::make('proposed_end_time')
                            ->required(),
                        Forms\Components\Textarea::make('reason')
                            ->columnSpanFull(),
                    ]),
                Forms\Components\Section::make(__('admin.forms.sections.Counter Schedule'))
                    ->icon('heroicon-o-arrow-left-right')
                    ->columns(2)
                    ->schema([
                        Forms\Components\DatePicker::make('counter_date')
                            ->default(null),
                        Forms\Components\TextInput::make('counter_start_time')
                            ->default(null),
                        Forms\Components\TextInput::make('counter_end_time')
                            ->default(null),
                        Forms\Components\Textarea::make('counter_reason')
                            ->columnSpanFull(),
                    ]),
                Forms\Components\Section::make(__('admin.forms.sections.Response'))
                    ->icon('heroicon-o-check-circle')
                    ->schema([
                        Forms\Components\DateTimePicker::make('responded_at'),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('booking.booking_number')
                    ->searchable()
                    ->sortable()
                    ->label(__('admin.forms.fields.Booking Number')),
                Tables\Columns\TextColumn::make('requester.name')
                    ->searchable()
                    ->sortable()
                    ->label(__('admin.forms.fields.Requested By')),
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->colors([
                        'warning' => 'pending',
                        'success' => 'approved',
                        'danger' => 'declined',
                        'info' => 'countered',
                    ])
                    ->formatStateUsing(fn (string $state): string => ucfirst($state)),
                Tables\Columns\TextColumn::make('proposed_date')
                    ->date()
                    ->sortable(),
                Tables\Columns\TextColumn::make('responded_at')
                    ->dateTime()
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
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        'pending' => 'Pending',
                        'approved' => 'Approved',
                        'declined' => 'Declined',
                        'countered' => 'Countered',
                    ]),
                Tables\Filters\Filter::make('proposed_date')
                    ->form([
                        Forms\Components\DatePicker::make('date_from'),
                        Forms\Components\DatePicker::make('date_until'),
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return $query
                            ->when(
                                $data['date_from'],
                                fn (Builder $query, $date): Builder => $query->whereDate('proposed_date', '>=', $date),
                            )
                            ->when(
                                $data['date_until'],
                                fn (Builder $query, $date): Builder => $query->whereDate('proposed_date', '<=', $date),
                            );
                    }),
            ])
            ->actions([
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
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListRescheduleRequests::route('/'),
            'create' => Pages\CreateRescheduleRequest::route('/create'),
            'edit' => Pages\EditRescheduleRequest::route('/{record}/edit'),
        ];
    }
}
