<?php

namespace App\Filament\Resources;

use App\Filament\Resources\NotificationTemplateResource\Pages;
use App\Filament\Resources\NotificationTemplateResource\RelationManagers;
use App\Models\NotificationTemplate;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class NotificationTemplateResource extends Resource
{
    protected static ?string $model = NotificationTemplate::class;

    protected static ?string $navigationIcon = 'heroicon-o-document-duplicate';
    protected static ?int $navigationSort = 320;
    protected static ?string $recordTitleAttribute = 'title_en';

    public static function getNavigationGroup(): ?string
    {
        return __('admin.navigation.groups.Communication');
    }

    public static function getModelLabel(): string
    {
        return __('admin.navigation.resources.Notification Templates');
    }

    public static function getPluralModelLabel(): string
    {
        return __('admin.navigation.resources.Notification Templates');
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make(__('admin.forms.sections.Details'))
                    ->columns(2)
                    ->schema([
                        Forms\Components\TextInput::make('action_key')
                            ->required()
                            ->maxLength(100)
                            ->unique(ignoreRecord: true),
                        Forms\Components\Select::make('category')
                            ->options([
                                'booking' => '📅 Booking',
                                'chat' => '💬 Chat',
                                'followers' => '👥 Followers',
                                'review' => '⭐ Review',
                                'security' => '🔒 Security',
                                'support' => '🆘 Support',
                                'system' => '📢 System',
                                'promo' => '🏷️ Promotional',
                            ])
                            ->searchable()
                            ->native(false)
                            ->default(null),
                        Forms\Components\TextInput::make('priority')
                            ->numeric()
                            ->default(0),
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
                        Forms\Components\TextInput::make('deep_link_type')
                            ->maxLength(50)
                            ->default(null),
                        Forms\Components\Toggle::make('allow_push'),
                        Forms\Components\Toggle::make('allow_in_app'),
                        Forms\Components\Toggle::make('allow_email'),
                        Forms\Components\Toggle::make('allow_sms'),
                    ]),
                Forms\Components\Section::make(__('admin.forms.sections.Content (EN)'))
                    ->icon('heroicon-o-language')
                    ->schema([
                        Forms\Components\TextInput::make('title_en')
                            ->required()
                            ->maxLength(255)
                            ->label(__('admin.forms.fields.Title (EN)')),
                        Forms\Components\Textarea::make('body_en')
                            ->required()
                            ->columnSpanFull()
                            ->label(__('admin.forms.fields.Body (EN)')),
                    ]),
                Forms\Components\Section::make(__('admin.forms.sections.Content (AR)'))
                    ->icon('heroicon-o-language')
                    ->schema([
                        Forms\Components\TextInput::make('title_ar')
                            ->required()
                            ->maxLength(255)
                            ->label(__('admin.forms.fields.Title (AR)')),
                        Forms\Components\Textarea::make('body_ar')
                            ->required()
                            ->columnSpanFull()
                            ->label(__('admin.forms.fields.Body (AR)')),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('action_key')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('title_en')
                    ->searchable()
                    ->limit(50)
                    ->label(__('admin.forms.fields.Title (EN)')),
                Tables\Columns\TextColumn::make('title_ar')
                    ->searchable()
                    ->limit(50)
                    ->label(__('admin.forms.fields.Title (AR)')),
                Tables\Columns\TextColumn::make('category')
                    ->badge()
                    ->searchable(),
                Tables\Columns\IconColumn::make('allow_push')
                    ->boolean()
                    ->label(__('admin.forms.fields.Allow Push')),
                Tables\Columns\IconColumn::make('allow_in_app')
                    ->boolean()
                    ->label(__('admin.forms.fields.Allow In-App')),
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
                Tables\Filters\SelectFilter::make('category')
                    ->label(__('admin.forms.fields.Category'))
                    ->options(function (): array {
                        return \App\Models\NotificationTemplate::distinct()->pluck('category', 'category')->toArray();
                    }),
                Tables\Filters\TernaryFilter::make('allow_push')
                    ->label(__('admin.forms.fields.Allow Push')),
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
            'index' => Pages\ListNotificationTemplates::route('/'),
            'create' => Pages\CreateNotificationTemplate::route('/create'),
            'edit' => Pages\EditNotificationTemplate::route('/{record}/edit'),
        ];
    }
}
