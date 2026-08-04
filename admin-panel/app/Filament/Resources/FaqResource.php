<?php

namespace App\Filament\Resources;

use App\Filament\Resources\FaqResource\Pages;
use App\Models\Faq;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class FaqResource extends Resource
{
    protected static ?string $model = Faq::class;

    protected static ?string $navigationIcon = 'heroicon-o-question-mark-circle';
    protected static ?int $navigationSort = 200;

    public static function getNavigationGroup(): ?string
    {
        return __('admin.navigation.groups.Content');
    }

    public static function getModelLabel(): string
    {
        return __('admin.navigation.resources.FAQs');
    }

    public static function getPluralModelLabel(): string
    {
        return __('admin.navigation.resources.FAQs');
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make(__('admin.forms.sections.English Content'))
                    ->schema([
                        Forms\Components\TextInput::make('question_en')
                            ->label(__('admin.forms.fields.Question (EN)'))
                            ->required()
                            ->maxLength(255),
                        Forms\Components\Textarea::make('answer_en')
                            ->label(__('admin.forms.fields.Answer (EN)'))
                            ->required()
                            ->rows(4),
                    ]),
                Forms\Components\Section::make(__('admin.forms.sections.Arabic Content'))
                    ->schema([
                        Forms\Components\TextInput::make('question_ar')
                            ->label(__('admin.forms.fields.Question (AR)'))
                            ->required()
                            ->maxLength(255),
                        Forms\Components\Textarea::make('answer_ar')
                            ->label(__('admin.forms.fields.Answer (AR)'))
                            ->required()
                            ->rows(4),
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
            ->columns([
                Tables\Columns\TextColumn::make('sort_order')
                    ->label(__('admin.forms.fields.Sort Order'))
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('question_en')
                    ->label(__('admin.forms.fields.Question (EN)'))
                    ->searchable()
                    ->limit(50),
                Tables\Columns\TextColumn::make('question_ar')
                    ->label(__('admin.forms.fields.Question (AR)'))
                    ->searchable()
                    ->limit(50),
                Tables\Columns\IconColumn::make('is_active')
                    ->label(__('admin.forms.fields.Is Active'))
                    ->boolean(),
                Tables\Columns\TextColumn::make('created_at')
                    ->label(__('admin.forms.fields.created_at'))
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
            'index' => Pages\ListFaqs::route('/'),
            'create' => Pages\CreateFaq::route('/create'),
            'edit' => Pages\EditFaq::route('/{record}/edit'),
        ];
    }
}
