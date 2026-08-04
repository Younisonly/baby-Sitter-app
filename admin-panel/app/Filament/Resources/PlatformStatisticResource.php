<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PlatformStatisticResource\Pages;
use App\Models\PlatformStatistic;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class PlatformStatisticResource extends Resource
{
    protected static ?string $model = PlatformStatistic::class;

    protected static ?string $navigationIcon = 'heroicon-o-chart-bar';
    protected static ?int $navigationSort = 450;
    protected static ?string $recordTitleAttribute = 'key';

    public static function getNavigationGroup(): ?string
    {
        return 'Configuration';
    }

    public static function getModelLabel(): string
    {
        return __('admin.navigation.resources.Platform Statistics');
    }

    public static function getPluralModelLabel(): string
    {
        return __('admin.navigation.resources.Platform Statistics');
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make(__('admin.forms.sections.General'))
                    ->schema([
                        Forms\Components\TextInput::make('key')
                            ->label(__('admin.forms.fields.Key'))
                            ->required()
                            ->maxLength(255)
                            ->unique(ignoreRecord: true)
                            ->disabledOn('edit')
                            ->helperText(__('admin.forms.helperTexts.Statistic Key')),
                        Forms\Components\TextInput::make('value')
                            ->label(__('admin.forms.fields.Value'))
                            ->required()
                            ->maxLength(255),
                        Forms\Components\TextInput::make('icon')
                            ->label(__('admin.forms.fields.Icon'))
                            ->maxLength(255)
                            ->placeholder('star_rounded'),
                    ])->columns(3),
                Forms\Components\Section::make(__('admin.forms.sections.Content (EN)'))
                    ->schema([
                        Forms\Components\TextInput::make('label')
                            ->label(__('admin.forms.fields.Label (EN)'))
                            ->required()
                            ->maxLength(255),
                    ]),
                Forms\Components\Section::make(__('admin.forms.sections.Content (AR)'))
                    ->schema([
                        Forms\Components\TextInput::make('label_ar')
                            ->label(__('admin.forms.fields.Label (AR)'))
                            ->required()
                            ->maxLength(255),
                    ]),
                Forms\Components\Section::make(__('admin.forms.sections.Settings'))
                    ->schema([
                        Forms\Components\TextInput::make('sort_order')
                            ->label(__('admin.forms.fields.Sort Order'))
                            ->required()
                            ->numeric()
                            ->default(0),
                        Forms\Components\Toggle::make('is_active')
                            ->label(__('admin.forms.fields.Is Active'))
                            ->required(),
                    ])->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('sort_order')
            ->reorderable('sort_order')
            ->columns([
                Tables\Columns\TextColumn::make('sort_order')
                    ->label(__('admin.forms.fields.Sort Order'))
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('key')
                    ->label(__('admin.forms.fields.Key'))
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('value')
                    ->label(__('admin.forms.fields.Value'))
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('label')
                    ->label(__('admin.forms.fields.Label (EN)'))
                    ->searchable(),
                Tables\Columns\TextColumn::make('label_ar')
                    ->label(__('admin.forms.fields.Label (AR)'))
                    ->searchable(),
                Tables\Columns\IconColumn::make('is_active')
                    ->label(__('admin.forms.fields.Is Active'))
                    ->boolean(),
                Tables\Columns\TextColumn::make('created_at')
                    ->label(__('admin.forms.fields.created_at'))
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('updated_at')
                    ->label(__('admin.forms.fields.updated_at'))
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
                Tables\Actions\DeleteAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListPlatformStatistics::route('/'),
            'create' => Pages\CreatePlatformStatistic::route('/create'),
            'edit' => Pages\EditPlatformStatistic::route('/{record}/edit'),
        ];
    }
}