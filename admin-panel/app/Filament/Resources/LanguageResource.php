<?php

namespace App\Filament\Resources;

use App\Filament\Resources\LanguageResource\Pages;
use App\Filament\Resources\LanguageResource\RelationManagers;
use App\Models\Language;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class LanguageResource extends Resource
{
    protected static ?string $model = Language::class;

    protected static ?string $navigationIcon = 'heroicon-o-language';
    protected static ?string $recordTitleAttribute = 'name';

    public static function getNavigationGroup(): ?string
    {
        return __('admin.navigation.groups.Configuration');
    }

    public static function getModelLabel(): string
    {
        return __('admin.navigation.resources.Languages');
    }

    public static function getPluralModelLabel(): string
    {
        return __('admin.navigation.resources.Languages');
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::make('name')
                    ->required()
                    ->maxLength(255)
                    ->label(__('admin.forms.fields.Name')),
                Forms\Components\TextInput::make('name_ar')
                    ->required()
                    ->maxLength(255)
                    ->label(__('admin.forms.fields.Name (AR)')),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('name')
            ->columns([
                Tables\Columns\TextColumn::make('name')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('name_ar')
                    ->searchable()
                    ->label(__('admin.forms.fields.Name (AR)')),
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
                //
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
            'index' => Pages\ListLanguages::route('/'),
            'create' => Pages\CreateLanguage::route('/create'),
            'edit' => Pages\EditLanguage::route('/{record}/edit'),
        ];
    }
}
