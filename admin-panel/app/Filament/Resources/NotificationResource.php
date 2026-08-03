<?php

namespace App\Filament\Resources;

use App\Filament\Resources\NotificationResource\Pages;
use App\Filament\Resources\NotificationResource\RelationManagers;
use App\Models\Notification;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class NotificationResource extends Resource
{
    protected static ?string $model = Notification::class;

    protected static ?string $navigationIcon = 'heroicon-o-bell';
    protected static ?string $recordTitleAttribute = 'title';

    public static function getNavigationGroup(): ?string
    {
        return __('admin.navigation.groups.Communication');
    }

    public static function getModelLabel(): string
    {
        return __('admin.navigation.resources.Notifications');
    }

    public static function getPluralModelLabel(): string
    {
        return __('admin.navigation.resources.Notifications');
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make(__('admin.forms.sections.Details'))
                    ->schema([
                        Forms\Components\Select::make('user_id')
                            ->relationship('user', 'name')
                            ->searchable()
                            ->required(),
                        Forms\Components\Select::make('template_id')
                            ->relationship('template', 'title_en')
                            ->searchable()
                            ->default(null),
                        Forms\Components\TextInput::make('title')
                            ->required()
                            ->maxLength(255),
                        Forms\Components\Textarea::make('body')
                            ->required()
                            ->columnSpanFull(),
                        Forms\Components\Select::make('type')
                            ->required()
                            ->options([
                                'system' => '📢 System Update',
                                'alert' => '⚠️ Important Alert',
                                'promo' => '🏷️ Promotional',
                                'booking' => '📅 Booking',
                                'security' => '🔒 Security',
                                'followers' => '👥 Followers',
                                'review' => '⭐ Review',
                                'support' => '🆘 Support',
                                'chat' => '💬 Chat',
                            ])
                            ->native(false)
                            ->searchable(),
                    ])
                    ->columns(2),
                Forms\Components\Section::make(__('admin.forms.sections.Settings'))
                    ->icon('heroicon-o-cog-6-tooth')
                    ->columns(2)
                    ->schema([
                        Forms\Components\Select::make('action_key')
                            ->options([
                                'booking_submitted' => 'Booking Submitted',
                                'booking_created' => 'Booking Created',
                                'booking_confirmed' => 'Booking Confirmed',
                                'booking_rejected' => 'Booking Rejected',
                                'booking_cancelled' => 'Booking Cancelled',
                                'booking_completed' => 'Booking Completed',
                                'booking_expired' => 'Booking Expired',
                                'booking_updated' => 'Booking Updated',
                                'booking_rescheduled' => 'Booking Rescheduled',
                                'new_booking_request' => 'New Booking Request',
                                'booking_confirmed_sitter' => 'Booking Confirmed (Sitter)',
                                'booking_cancelled_sitter' => 'Booking Cancelled (Sitter)',
                                'booking_rejected_sitter' => 'Booking Rejected (Sitter)',
                                'booking_in_progress' => 'Booking In Progress',
                                'booking_in_progress_sitter' => 'Booking In Progress (Sitter)',
                                'booking_completed_sitter' => 'Booking Completed (Sitter)',
                                'booking_reminder' => 'Booking Reminder',
                                'review_received' => 'Review Received',
                                'review_updated' => 'Review Updated',
                                'new_follower' => 'New Follower',
                                'support_ticket' => 'Support Ticket',
                                'system_announcement' => 'System Announcement',
                                'account_suspended' => 'Account Suspended',
                                'password_changed' => 'Password Changed',
                            ])
                            ->searchable()
                            ->native(false)
                            ->default(null),
                        Forms\Components\Select::make('priority')
                            ->options([
                                0 => '🟢 Normal (0)',
                                1 => '🟡 Low (1)',
                                2 => '🟠 Medium (2)',
                                3 => '🔴 High (3)',
                                4 => '🚨 Critical (4)',
                            ])
                            ->default(0)
                            ->native(false),
                        Forms\Components\Select::make('icon')
                            ->options([
                                'bell' => '🔔 Bell',
                                'calendar' => '📅 Calendar',
                                'check' => '✅ Check',
                                'clock' => '🕐 Clock',
                                'credit-card' => '💳 Credit Card',
                                'danger' => '⚠️ Danger',
                                'envelope' => '✉️ Envelope',
                                'exclamation' => '❗ Exclamation',
                                'eye' => '👁️ Eye',
                                'fire' => '🔥 Fire',
                                'gift' => '🎁 Gift',
                                'hand' => '✋ Hand',
                                'heart' => '❤️ Heart',
                                'info' => 'ℹ️ Info',
                                'lock' => '🔒 Lock',
                                'megaphone' => '📢 Megaphone',
                                'message' => '💬 Message',
                                'people' => '👥 People',
                                'person' => '👤 Person',
                                'question' => '❓ Question',
                                'shield' => '🛡️ Shield',
                                'star' => '⭐ Star',
                                'support' => '🆘 Support',
                                'trash' => '🗑️ Trash',
                                'user' => '👤 User',
                                'x' => '❌ X',
                            ])
                            ->searchable()
                            ->native(false)
                            ->default(null),
                        Forms\Components\TextInput::make('image')
                            ->maxLength(500)
                            ->default(null),
                        Forms\Components\TextInput::make('deep_link_type')
                            ->maxLength(50)
                            ->default(null),
                        Forms\Components\TextInput::make('deep_link_id')
                            ->maxLength(36)
                            ->default(null),
                        Forms\Components\Toggle::make('show_push'),
                        Forms\Components\Toggle::make('show_in_app'),
                        Forms\Components\Toggle::make('is_read'),
                        Forms\Components\DateTimePicker::make('read_at'),
                        Forms\Components\TextInput::make('language')
                            ->maxLength(5)
                            ->default(null),
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
                Tables\Columns\TextColumn::make('title')
                    ->searchable()
                    ->limit(50),
                Tables\Columns\TextColumn::make('type')
                    ->badge()
                    ->searchable(),
                Tables\Columns\IconColumn::make('is_read')
                    ->boolean()
                    ->label(__('admin.forms.fields.Is Read')),
                Tables\Columns\IconColumn::make('show_push')
                    ->boolean()
                    ->label(__('admin.forms.fields.Show Push')),
                Tables\Columns\TextColumn::make('priority')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable(),
                Tables\Columns\TextColumn::make('updated_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\TernaryFilter::make('is_read')
                    ->label(__('admin.filters.Is Read')),
                Tables\Filters\SelectFilter::make('type')
                    ->label(__('admin.forms.fields.Type'))
                    ->options(function (): array {
                        return Notification::distinct()->pluck('type', 'type')->toArray();
                    }),
                Tables\Filters\TernaryFilter::make('show_push')
                    ->label(__('admin.forms.fields.Show Push')),
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
            'index' => Pages\ListNotifications::route('/'),
            'create' => Pages\CreateNotification::route('/create'),
            'edit' => Pages\EditNotification::route('/{record}/edit'),
        ];
    }
}
