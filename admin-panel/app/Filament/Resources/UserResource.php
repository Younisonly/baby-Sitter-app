<?php

namespace App\Filament\Resources;

use App\Filament\Resources\UserResource\Pages;
use App\Filament\Resources\UserResource\RelationManagers;
use App\Filament\Pages\CreateAdmin;
use App\Models\User;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class UserResource extends Resource
{
    protected static ?string $model = User::class;

    protected static ?string $navigationIcon = 'heroicon-o-users';
    protected static ?string $navigationGroup = 'User Management';
    protected static ?string $recordTitleAttribute = 'name';

    public static function canViewAny(): bool
    {
        return (bool) auth()->user()?->isAdmin();
    }

    public static function canView($record): bool
    {
        $user = auth()->user();
        if ($user?->isSuperAdmin()) {
            return true;
        }

        return $record->id === $user?->id || ! in_array($record->role, ['super_admin', 'admin'], true);
    }

    public static function canCreate(): bool
    {
        return (bool) auth()->user()?->isAdmin();
    }

    public static function canEdit($record): bool
    {
        $user = auth()->user();
        if ($user?->isSuperAdmin()) {
            return true;
        }

        return $record->id === $user?->id || ! in_array($record->role, ['super_admin', 'admin'], true);
    }

    public static function canDelete($record): bool
    {
        $user = auth()->user();
        if ($record->id === $user?->id) {
            return false;
        }

        return $user?->isSuperAdmin() || ! in_array($record->role, ['super_admin', 'admin'], true);
    }

    public static function canDeleteAny(): bool
    {
        return (bool) auth()->user()?->isSuperAdmin();
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Account Information')
                    ->icon('heroicon-o-user')
                    ->columns(2)
                    ->schema([
                        Forms\Components\TextInput::make('name')
                            ->required()
                            ->maxLength(255),
                        Forms\Components\TextInput::make('email')
                            ->email()
                            ->required()
                            ->maxLength(255),
                        Forms\Components\TextInput::make('phone')
                            ->tel()
                            ->maxLength(255)
                            ->default(null),
                        Forms\Components\TextInput::make('password')
                            ->password()
                            ->dehydrated(fn ($state) => filled($state))
                            ->required(fn (string $operation): bool => $operation === 'create')
                            ->maxLength(255),
                        Forms\Components\TextInput::make('preferred_language')
                            ->label('Language')
                            ->default('en')
                            ->maxLength(5),
                        Forms\Components\TextInput::make('national_id')
                            ->maxLength(20)
                            ->default(null),
                    ]),
                Forms\Components\Section::make('Profile')
                    ->icon('heroicon-o-identification')
                    ->columns(2)
                    ->schema([
                        Forms\Components\TextInput::make('avatar')
                            ->maxLength(255)
                            ->default(null),
                        Forms\Components\Textarea::make('bio')
                            ->columnSpanFull(),
                        Forms\Components\TextInput::make('location')
                            ->maxLength(255)
                            ->default(null),
                        Forms\Components\TextInput::make('latitude')
                            ->numeric()
                            ->default(null),
                        Forms\Components\TextInput::make('longitude')
                            ->numeric()
                            ->default(null),
                        Forms\Components\TextInput::make('age')
                            ->numeric()
                            ->default(null),
                        Forms\Components\Select::make('gender')
                            ->options([
                                'male' => 'Male',
                                'female' => 'Female',
                            ])
                            ->default(null),
                        Forms\Components\Textarea::make('languages')
                            ->columnSpanFull(),
                    ]),
                Forms\Components\Section::make('Verification & Status')
                    ->icon('heroicon-o-shield-check')
                    ->columns(2)
                    ->schema([
                        Forms\Components\Select::make('role')
                            ->options(function (): array {
                                if (auth()->user()?->isSuperAdmin()) {
                                    return [
                                        'super_admin' => 'Super Admin',
                                        'admin' => 'Admin',
                                        'babysitter' => 'Babysitter',
                                        'customer' => 'Customer',
                                    ];
                                }

                                return [
                                    'babysitter' => 'Babysitter',
                                    'customer' => 'Customer',
                                ];
                            })
                            ->disabled(fn (?User $record): bool => $record !== null && $record->id === auth()->id())
                            ->helperText(fn (?User $record): ?string => $record !== null && $record->id === auth()->id()
                                ? 'You cannot change your own role.'
                                : null)
                            ->required(),
                        Forms\Components\Select::make('verification_status')
                            ->options([
                                'unverified' => 'Unverified',
                                'under_review' => 'Under Review',
                                'verified' => 'Verified',
                                'rejected' => 'Rejected',
                            ])
                            ->required(),
                        Forms\Components\TextInput::make('registration_status')
                            ->required()
                            ->maxLength(30)
                            ->default('none'),
                        Forms\Components\Toggle::make('is_suspended')
                            ->required(),
                        Forms\Components\Textarea::make('suspension_reason')
                            ->columnSpanFull(),
                        Forms\Components\DateTimePicker::make('suspended_at'),
                        Forms\Components\Toggle::make('has_parent_profile'),
                        Forms\Components\Toggle::make('has_sitter_profile'),
                    ]),
                Forms\Components\Section::make('Timestamps')
                    ->icon('heroicon-o-clock')
                    ->columns(2)
                    ->schema([
                        Forms\Components\DateTimePicker::make('email_verified_at'),
                        Forms\Components\DateTimePicker::make('last_seen_at'),
                        Forms\Components\DateTimePicker::make('became_parent_at'),
                        Forms\Components\DateTimePicker::make('became_sitter_at'),
                        Forms\Components\TextInput::make('provider')
                            ->maxLength(255)
                            ->default(null),
                        Forms\Components\TextInput::make('provider_id')
                            ->maxLength(255)
                            ->default(null),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->modifyQueryUsing(
                fn (Builder $query): Builder => auth()->user()?->isSuperAdmin()
                    ? $query
                    : $query->whereNotIn('role', ['super_admin', 'admin']),
            )
            ->columns([
                Tables\Columns\TextColumn::make('name')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('email')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('role')
                    ->badge()
                    ->colors([
                        'gray' => 'customer',
                        'primary' => 'babysitter',
                        'danger' => 'admin',
                        'success' => 'super_admin',
                    ])
                    ->formatStateUsing(fn (string $state): string => $state === 'super_admin' ? 'Super Admin' : ucfirst($state)),
                Tables\Columns\TextColumn::make('verification_status')
                    ->badge()
                    ->colors([
                        'gray' => 'unverified',
                        'warning' => 'under_review',
                        'success' => 'verified',
                        'danger' => 'rejected',
                    ])
                    ->formatStateUsing(fn (string $state): string => str_replace('_', ' ', ucfirst($state))),
                Tables\Columns\IconColumn::make('is_suspended')
                    ->boolean()
                    ->label('Suspended'),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable(),
                Tables\Columns\TextColumn::make('phone')
                    ->searchable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('email_verified_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('location')
                    ->searchable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('age')
                    ->numeric()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('gender')
                    ->searchable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('registration_status')
                    ->searchable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\IconColumn::make('has_parent_profile')
                    ->boolean()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\IconColumn::make('has_sitter_profile')
                    ->boolean()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('preferred_language')
                    ->searchable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('updated_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('role')
                    ->options(fn (): array => auth()->user()?->isSuperAdmin()
                        ? [
                            'super_admin' => 'Super Admin',
                            'admin' => 'Admin',
                            'babysitter' => 'Babysitter',
                            'customer' => 'Customer',
                        ]
                        : [
                            'babysitter' => 'Babysitter',
                            'customer' => 'Customer',
                        ]),
                Tables\Filters\SelectFilter::make('verification_status')
                    ->options([
                        'unverified' => 'Unverified',
                        'under_review' => 'Under Review',
                        'verified' => 'Verified',
                        'rejected' => 'Rejected',
                    ]),
                Tables\Filters\TernaryFilter::make('is_suspended')
                    ->label('Suspended'),
                Tables\Filters\Filter::make('created_at')
                    ->form([
                        Forms\Components\DatePicker::make('created_from'),
                        Forms\Components\DatePicker::make('created_until'),
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return $query
                            ->when(
                                $data['created_from'],
                                fn (Builder $query, $date): Builder => $query->whereDate('created_at', '>=', $date),
                            )
                            ->when(
                                $data['created_until'],
                                fn (Builder $query, $date): Builder => $query->whereDate('created_at', '<=', $date),
                            );
                    }),
            ])
            ->actions([
                Tables\Actions\Action::make('Send Notification')
                    ->icon('heroicon-o-paper-airplane')
                    ->color('primary')
                    ->form([
                        Forms\Components\TextInput::make('title')
                            ->required()
                            ->maxLength(255),
                        Forms\Components\Textarea::make('body')
                            ->required(),
                        Forms\Components\Select::make('type')
                            ->options([
                                'system' => 'System',
                                'alert' => 'Alert',
                                'promo' => 'Promotional',
                            ])
                            ->default('system'),
                    ])
                    ->action(function (User $record, array $data): void {
                        \App\Models\Notification::create([
                            'user_id' => $record->id,
                            'title' => $data['title'],
                            'body' => $data['body'],
                            'type' => $data['type'] ?? 'system',
                            'language' => $record->preferred_language ?? 'en',
                            'show_push' => true,
                            'show_in_app' => true,
                            'is_read' => false,
                        ]);
                        \Filament\Notifications\Notification::make()
                            ->title('Notification sent to ' . $record->name)
                            ->success()
                            ->send();
                    }),
                Tables\Actions\Action::make('Suspend')
                    ->icon('heroicon-o-no-symbol')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->form([
                        Forms\Components\Textarea::make('suspension_reason')
                            ->label('Suspension Reason')
                            ->required(),
                    ])
                    ->action(function (User $record, array $data): void {
                        $record->update([
                            'is_suspended' => true,
                            'suspension_reason' => $data['suspension_reason'],
                            'suspended_at' => now(),
                        ]);
                    })
                    ->visible(fn (User $record): bool => ! $record->is_suspended && $record->id !== auth()->id()),
                Tables\Actions\Action::make('Reinstate')
                    ->icon('heroicon-o-check-circle')
                    ->color('success')
                    ->requiresConfirmation()
                    ->action(function (User $record): void {
                        $record->update([
                            'is_suspended' => false,
                            'suspension_reason' => null,
                            'suspended_at' => null,
                        ]);
                    })
                    ->visible(fn (User $record): bool => $record->is_suspended && $record->id !== auth()->id()),
                Tables\Actions\Action::make('Verify Email')
                    ->icon('heroicon-o-check-badge')
                    ->color('success')
                    ->requiresConfirmation()
                    ->action(fn (User $record) => $record->update(['email_verified_at' => now()]))
                    ->visible(fn (User $record): bool => is_null($record->email_verified_at)),
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ])
            ->headerActions([
                Tables\Actions\Action::make('create_admin')
                    ->label('Create Admin')
                    ->icon('heroicon-o-user-plus')
                    ->color('primary')
                    ->visible(fn (): bool => (bool) auth()->user()?->isSuperAdmin())
                    ->url(fn (): string => CreateAdmin::getUrl()),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            RelationManagers\UserBookingsRelationManager::class,
            RelationManagers\UserDevicesRelationManager::class,
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListUsers::route('/'),
            'create' => Pages\CreateUser::route('/create'),
            'edit' => Pages\EditUser::route('/{record}/edit'),
        ];
    }
}
