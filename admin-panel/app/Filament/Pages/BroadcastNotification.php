<?php

namespace App\Filament\Pages;

use App\Models\User;
use App\Models\Notification as NotificationModel;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Contracts\HasForms;
use Filament\Notifications\Notification;
use Filament\Pages\Page;

class BroadcastNotification extends Page implements HasForms
{
    use InteractsWithForms;

    protected static ?string $navigationIcon = 'heroicon-o-megaphone';
    protected static ?int $navigationSort = 330;
    protected static string $view = 'filament.pages.broadcast-notification';

    public ?array $data = [];

    public static function getNavigationGroup(): ?string
    {
        return 'Communication';
    }

    public static function getNavigationLabel(): string
    {
        return __('admin.navigation.resources.Broadcast Notifications');
    }

    public function mount(): void
    {
        $this->form->fill([
            'target_audience' => 'all',
            'type' => 'system',
            'priority' => 'normal',
            'show_push' => true,
            'show_in_app' => true,
        ]);
    }

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make(__('admin.forms.sections.Details'))
                    ->columns(2)
                    ->schema([
                        Forms\Components\Select::make('target_audience')
                            ->label('Target Audience')
                            ->options([
                                'all' => '👥 All Users',
                                'babysitter' => '🧑‍🍼 All Babysitters',
                                'customer' => '👪 All Parents',
                                'unverified_sitters' => '⏳ Unverified Sitters',
                            ])
                            ->required()
                            ->native(false),

                        Forms\Components\Select::make('type')
                            ->label('Notification Type')
                            ->options([
                                'system' => '📢 System Update',
                                'alert' => '⚠️ Important Alert',
                                'promo' => '🏷️ Promotional',
                            ])
                            ->required()
                            ->native(false),

                        Forms\Components\TextInput::make('title')
                            ->label('Title')
                            ->required()
                            ->maxLength(255)
                            ->columnSpanFull(),

                        Forms\Components\Textarea::make('body')
                            ->label('Message Body')
                            ->required()
                            ->rows(4)
                            ->columnSpanFull(),

                        Forms\Components\Toggle::make('show_push')
                            ->label('Send Push Notification')
                            ->default(true),

                        Forms\Components\Toggle::make('show_in_app')
                            ->label('Show In-App Notification')
                            ->default(true),
                    ]),
            ])
            ->statePath('data');
    }

    public function sendBroadcast(): void
    {
        $state = $this->form->getState();

        $query = User::query();

        if ($state['target_audience'] === 'babysitter') {
            $query->where('role', 'babysitter');
        } elseif ($state['target_audience'] === 'customer') {
            $query->where('role', 'customer');
        } elseif ($state['target_audience'] === 'unverified_sitters') {
            $query->where('role', 'babysitter')->where('verification_status', '!=', 'verified');
        }

        $users = $query->get();
        $count = 0;

        foreach ($users as $user) {
            NotificationModel::create([
                'user_id' => $user->id,
                'title' => $state['title'],
                'body' => $state['body'],
                'type' => $state['type'],
                'language' => $user->preferred_language ?? 'en',
                'show_push' => $state['show_push'],
                'show_in_app' => $state['show_in_app'],
                'is_read' => false,
            ]);
            $count++;
        }

        Notification::make()
            ->title("Broadcast Sent!")
            ->body("Successfully sent notification to {$count} users.")
            ->success()
            ->send();

        $this->form->fill([
            'target_audience' => 'all',
            'type' => 'system',
            'title' => '',
            'body' => '',
            'show_push' => true,
            'show_in_app' => true,
        ]);
    }
}
