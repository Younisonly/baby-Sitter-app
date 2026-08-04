<?php

namespace App\Filament\Pages;

use App\Models\User;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Contracts\HasForms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Illuminate\Support\Facades\Hash;

class CreateAdmin extends Page implements HasForms
{
    use InteractsWithForms;

    protected static ?string $navigationIcon = 'heroicon-o-user-plus';
    protected static ?int $navigationSort = 30;

    public static function getNavigationGroup(): ?string
    {
        return 'User Management';
    }
    protected static string $view = 'filament.pages.create-admin';
    protected static ?string $slug = 'users/create-admin';

    public ?array $data = [];

    public static function getNavigationLabel(): string
    {
        return __('admin.navigation.resources.Create Admin');
    }

    public function getTitle(): string
    {
        return __('admin.pages.create_admin.title');
    }

    public static function canAccess(): bool
    {
        return (bool) auth()->user()?->isSuperAdmin();
    }

    public function mount(): void
    {
        $this->form->fill(['role' => 'admin']);
    }

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                TextInput::make('name')
                    ->label(__('admin.pages.create_admin.fields.name'))
                    ->required()
                    ->maxLength(255),
                TextInput::make('email')
                    ->label(__('admin.pages.create_admin.fields.email'))
                    ->email()
                    ->required()
                    ->unique(table: User::class, column: 'email')
                    ->maxLength(255),
                TextInput::make('phone')
                    ->label(__('admin.pages.create_admin.fields.phone'))
                    ->tel()
                    ->maxLength(20),
                TextInput::make('password')
                    ->label(__('admin.pages.create_admin.fields.password'))
                    ->password()
                    ->revealable()
                    ->required()
                    ->minLength(8)
                    ->maxLength(255)
                    ->same('password_confirmation'),
                TextInput::make('password_confirmation')
                    ->label(__('admin.pages.create_admin.fields.password_confirmation'))
                    ->password()
                    ->revealable()
                    ->required(),
                Select::make('role')
                    ->label(__('admin.pages.create_admin.fields.role'))
                    ->options([
                        'admin' => __('admin.pages.create_admin.roles.admin'),
                        'super_admin' => __('admin.pages.create_admin.roles.super_admin'),
                    ])
                    ->default('admin')
                    ->required(),
            ])
            ->statePath('data');
    }

    public function create(): void
    {
        $state = $this->form->getState();

        $user = User::create([
            'name' => trim(strip_tags($state['name'])),
            'email' => strtolower(trim($state['email'])),
            'phone' => $state['phone'] ?? null,
            'password' => Hash::make($state['password']),
            'role' => $state['role'],
            'email_verified_at' => now(),
            'verification_status' => 'verified',
            'preferred_language' => 'en',
        ]);

        Notification::make()
            ->title(__('admin.pages.create_admin.success_title'))
            ->body(__('admin.pages.create_admin.success_body', ['name' => $user->name, 'role' => ucfirst(str_replace('_', ' ', $user->role))]))
            ->success()
            ->send();

        $this->redirect(\App\Filament\Resources\UserResource::getUrl('index'));
    }
}
