<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ServiceCategoryResource\Pages;
use App\Models\ServiceCategory;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class ServiceCategoryResource extends Resource
{
    protected static ?string $model = ServiceCategory::class;

    protected static ?string $navigationIcon = 'heroicon-o-tag';
    protected static ?int $navigationSort = 210;
    protected static ?string $recordTitleAttribute = 'label';

    public static function getNavigationGroup(): ?string
    {
        return __('admin.navigation.groups.Content');
    }

    public static function getModelLabel(): string
    {
        return __('admin.navigation.resources.Service Categories');
    }

    public static function getPluralModelLabel(): string
    {
        return __('admin.navigation.resources.Service Categories');
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make(__('admin.forms.sections.General'))
                    ->columns(2)
                    ->schema([
                        Forms\Components\TextInput::make('key')
                            ->required()
                            ->maxLength(255),
                        Forms\Components\TextInput::make('sort_order')
                            ->required()
                            ->numeric()
                            ->default(0),
                        Forms\Components\Toggle::make('is_active')
                            ->required(),
                    ]),
                Forms\Components\Section::make(__('admin.forms.sections.English Content'))
                    ->columns(2)
                    ->schema([
                        Forms\Components\TextInput::make('label')
                            ->label(__('admin.forms.fields.Label (EN)'))
                            ->required()
                            ->maxLength(255),
                        Forms\Components\Textarea::make('description')
                            ->label(__('admin.forms.fields.Description (EN)'))
                            ->columnSpanFull(),
                    ]),
                Forms\Components\Section::make(__('admin.forms.sections.Arabic Content'))
                    ->columns(2)
                    ->schema([
                        Forms\Components\TextInput::make('label_ar')
                            ->label(__('admin.forms.fields.Label (AR)'))
                            ->maxLength(255),
                        Forms\Components\Textarea::make('description_ar')
                            ->label(__('admin.forms.fields.Description (AR)'))
                            ->columnSpanFull(),
                    ]),
                Forms\Components\Section::make(__('admin.forms.sections.Appearance'))
                    ->columns(2)
                    ->schema([
                        Forms\Components\Select::make('icon')
                            ->required()
                            ->options([
                                'baby' => '👶 Baby',
                                'child_care' => '🧒 Child Care',
                                'toddler' => '🚼 Toddler',
                                'newborn' => '🍼 Newborn',
                                'preschool' => '📚 Preschool',
                                'school' => '🎒 School',
                                'special_needs' => '❤️ Special Needs',
                                'kids' => '😊 Kids',
                                'family' => '👪 Family',
                                'heart' => '❤️ Heart',
                                'favorite' => '⭐ Favorite',
                                'favorite_border' => '☆ Favorite Outline',
                                'spa' => '🧘 Spa',
                                'self_improvement' => '🧘 Self Improvement',
                                'overnight' => '🌙 Overnight',
                                'moon' => '🌙 Moon',
                                'nightlight' => '🌙 Nightlight',
                                'emergency' => '🚨 Emergency',
                                'health_and_safety' => '🛡️ Health & Safety',
                                'person' => '👤 Person',
                                'emoji_people' => '🤝 Social',
                            ])
                            ->searchable()
                            ->native(false)
                            ->default('child_care'),
                        Forms\Components\TextInput::make('color')
                            ->required()
                            ->maxLength(7)
                            ->default('#2563EB'),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('sort_order')
            ->columns([
                Tables\Columns\TextColumn::make('label')
                    ->searchable()
                    ->sortable()
                    ->label('Category')
                    ->formatStateUsing(fn ($record) => self::iconEmoji($record?->icon) . ($record?->label ?? '')),
                Tables\Columns\TextColumn::make('label_ar')
                    ->searchable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\ColorColumn::make('color')
                    ->label('Color'),
                Tables\Columns\TextColumn::make('sort_order')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\IconColumn::make('is_active')
                    ->boolean(),
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
                Tables\Filters\TernaryFilter::make('is_active')
                    ->label(__('admin.filters.Is Active')),
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

    public static function iconEmoji(?string $icon): string
    {
        return match ($icon) {
            'baby' => '👶 ',
            'child_care' => '🧒 ',
            'toddler' => '🚼 ',
            'newborn' => '🍼 ',
            'preschool' => '📚 ',
            'school' => '🎒 ',
            'special_needs' => '❤️ ',
            'kids' => '😊 ',
            'family' => '👪 ',
            'heart' => '❤️ ',
            'favorite' => '⭐ ',
            'favorite_border' => '☆ ',
            'spa' => '🧘 ',
            'self_improvement' => '🧘 ',
            'overnight' => '🌙 ',
            'moon' => '🌙 ',
            'nightlight' => '🌙 ',
            'emergency' => '🚨 ',
            'health_and_safety' => '🛡️ ',
            'person' => '👤 ',
            'emoji_people' => '🤝 ',
            default => '',
        };
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListServiceCategories::route('/'),
            'create' => Pages\CreateServiceCategory::route('/create'),
            'edit' => Pages\EditServiceCategory::route('/{record}/edit'),
        ];
    }
}
