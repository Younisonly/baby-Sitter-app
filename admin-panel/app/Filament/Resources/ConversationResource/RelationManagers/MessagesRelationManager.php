<?php

namespace App\Filament\Resources\ConversationResource\RelationManagers;

use App\Models\Conversation;
use App\Models\Message;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;

class MessagesRelationManager extends RelationManager
{
    protected static string $relationship = 'messages';

    protected static ?string $recordTitleAttribute = 'id';

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Select::make('sender_id')
                    ->relationship('sender', 'name')
                    ->required()
                    ->searchable(),
                Forms\Components\Textarea::make('content')
                    ->required()
                    ->columnSpanFull(),
                Forms\Components\TextInput::make('type')
                    ->default('text'),
                Forms\Components\TextInput::make('image_url')
                    ->url(),
                Forms\Components\Toggle::make('is_system'),
            ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'asc')
            ->columns([
                Tables\Columns\TextColumn::make('sender.name')
                    ->label(__('admin.forms.fields.Last Sender'))
                    ->description(fn (Message $record): string => $record->is_system ? '⚙️ System Notice' : ($record->sender?->role ? ucfirst($record->sender->role) : 'User'))
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('content')
                    ->label(__('admin.forms.fields.Last Message'))
                    ->wrap()
                    ->searchable()
                    ->formatStateUsing(function (Message $record, ?string $state): string {
                        if ($record->is_system) {
                            return '⚙️ [System Notice]: ' . ($state ?? '');
                        }
                        return $state ?? '—';
                    }),
                Tables\Columns\ImageColumn::make('image_url')
                    ->label('Attachment')
                    ->circular(false)
                    ->square(),
                Tables\Columns\TextColumn::make('type')
                    ->badge()
                    ->colors([
                        'gray' => 'text',
                        'info' => 'image',
                        'warning' => 'audio',
                        'danger' => 'system',
                    ]),
                Tables\Columns\IconColumn::make('read_at')
                    ->label(__('admin.forms.fields.Is Read'))
                    ->boolean()
                    ->getStateUsing(fn (Message $record): bool => !is_null($record->read_at)),
                Tables\Columns\TextColumn::make('created_at')
                    ->label(__('admin.forms.fields.Timestamps'))
                    ->dateTime()
                    ->sortable(),
            ])
            ->filters([
                Tables\Filters\TernaryFilter::make('is_system')
                    ->label('System Messages'),
                Tables\Filters\TrashedFilter::make(),
            ])
            ->headerActions([
                Tables\Actions\Action::make('Send Admin Message')
                    ->icon('heroicon-o-paper-airplane')
                    ->color('primary')
                    ->form([
                        Forms\Components\Textarea::make('content')
                            ->label('Admin / System Notice Message')
                            ->required(),
                        Forms\Components\Toggle::make('is_system')
                            ->label('Mark as Official System Notice')
                            ->default(true),
                    ])
                    ->action(function (array $data): void {
                        /** @var Conversation $conversation */
                        $conversation = $this->getOwnerRecord();

                        $adminUser = auth()->user();

                        $message = Message::create([
                            'conversation_id' => $conversation->id,
                            'sender_id' => $conversation->participant_one_id,
                            'content' => $data['content'],
                            'type' => 'text',
                            'is_system' => $data['is_system'] ?? true,
                        ]);

                        $conversation->update([
                            'last_message_content' => $data['content'],
                            'last_message_type' => 'text',
                            'last_message_at' => now(),
                            'last_sender_id' => $adminUser?->id ?? $conversation->participant_one_id,
                        ]);

                        Notification::make()
                            ->title('Admin message posted to chat thread')
                            ->success()
                            ->send();
                    }),
                Tables\Actions\CreateAction::make(),
            ])
            ->actions([
                Tables\Actions\EditAction::make()
                    ->form([
                        Forms\Components\Textarea::make('content')
                            ->label('Edit Message Content')
                            ->required(),
                    ]),
                Tables\Actions\DeleteAction::make()
                    ->requiresConfirmation(),
                Tables\Actions\RestoreAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                    Tables\Actions\RestoreBulkAction::make(),
                ]),
            ]);
    }
}
