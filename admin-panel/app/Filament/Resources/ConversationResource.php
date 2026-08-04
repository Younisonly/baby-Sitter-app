<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ConversationResource\Pages;
use App\Filament\Resources\ConversationResource\RelationManagers;
use App\Models\Conversation;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class ConversationResource extends Resource
{
    protected static ?string $model = Conversation::class;

    protected static ?string $navigationIcon = 'heroicon-o-chat-bubble-left-right';
    protected static ?int $navigationSort = 300;
    protected static ?string $recordTitleAttribute = 'id';

    public static function getNavigationGroup(): ?string
    {
        return 'Communication';
    }

    public static function getModelLabel(): string
    {
        return __('admin.navigation.resources.Conversations');
    }

    public static function getPluralModelLabel(): string
    {
        return __('admin.navigation.resources.Conversations');
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make(__('admin.forms.sections.Details'))
                    ->columns(2)
                    ->schema([
                        Forms\Components\Select::make('participant_one_id')
                            ->relationship('participantOne', 'name')
                            ->searchable()
                            ->required()
                            ->label(__('admin.forms.fields.Participant One')),
                        Forms\Components\Select::make('participant_two_id')
                            ->relationship('participantTwo', 'name')
                            ->searchable()
                            ->required()
                            ->label(__('admin.forms.fields.Participant Two')),
                        Forms\Components\Textarea::make('last_message_content')
                            ->columnSpanFull()
                            ->label(__('admin.forms.fields.Last Message')),
                        Forms\Components\TextInput::make('last_message_type')
                            ->maxLength(50)
                            ->default(null),
                        Forms\Components\DateTimePicker::make('last_message_at'),
                        Forms\Components\Select::make('last_sender_id')
                            ->relationship('lastSender', 'name')
                            ->searchable()
                            ->default(null)
                            ->label(__('admin.forms.fields.Last Sender')),
                        Forms\Components\DateTimePicker::make('archived_at'),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('last_message_at', 'desc')
            ->columns([
                Tables\Columns\TextColumn::make('participantOne.name')
                    ->searchable()
                    ->sortable()
                    ->label(__('admin.forms.fields.Participant One')),
                Tables\Columns\TextColumn::make('participantTwo.name')
                    ->searchable()
                    ->sortable()
                    ->label(__('admin.forms.fields.Participant Two')),
                Tables\Columns\TextColumn::make('last_message_content')
                    ->limit(60)
                    ->searchable(),
                Tables\Columns\TextColumn::make('last_message_at')
                    ->dateTime()
                    ->sortable()
                    ->label(__('admin.forms.fields.Last Message At')),
                Tables\Columns\IconColumn::make('archived_at')
                    ->label('Archived')
                    ->boolean()
                    ->getStateUsing(fn (Conversation $record): bool => !is_null($record->archived_at)),
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
                Tables\Filters\SelectFilter::make('participant_one_id')
                    ->label(__('admin.forms.fields.Participant One'))
                    ->relationship('participantOne', 'name')
                    ->searchable(),
                Tables\Filters\SelectFilter::make('participant_two_id')
                    ->label(__('admin.forms.fields.Participant Two'))
                    ->relationship('participantTwo', 'name')
                    ->searchable(),
                Tables\Filters\TernaryFilter::make('archived_at')
                    ->label('Archived')
                    ->nullable(),
            ])
            ->actions([
                Tables\Actions\Action::make('Archive')
                    ->icon('heroicon-o-archive-box')
                    ->color('warning')
                    ->requiresConfirmation()
                    ->action(fn (Conversation $record) => $record->update(['archived_at' => now()]))
                    ->visible(fn (Conversation $record): bool => is_null($record->archived_at)),
                Tables\Actions\Action::make('Unarchive')
                    ->icon('heroicon-o-arrow-path')
                    ->color('success')
                    ->requiresConfirmation()
                    ->action(fn (Conversation $record) => $record->update(['archived_at' => null]))
                    ->visible(fn (Conversation $record): bool => !is_null($record->archived_at)),
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
            RelationManagers\MessagesRelationManager::class,
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListConversations::route('/'),
            'create' => Pages\CreateConversation::route('/create'),
            'edit' => Pages\EditConversation::route('/{record}/edit'),
        ];
    }
}
