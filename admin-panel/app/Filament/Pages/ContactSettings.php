<?php

namespace App\Filament\Pages;

use App\Models\ContactSetting;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Contracts\HasForms;
use Filament\Notifications\Notification;
use Filament\Pages\Page;

class ContactSettings extends Page implements HasForms
{
    use InteractsWithForms;

    protected static ?string $navigationIcon = 'heroicon-o-phone';
    protected static ?int $navigationSort = 5;

    public static function getNavigationGroup(): ?string
    {
        return __('admin.navigation.groups.Configuration');
    }
    protected static string $view = 'filament.pages.contact-settings';

    public ?array $data = [];

    public function mount(): void
    {
        $settings = ContactSetting::firstOrCreate([]);
        $this->form->fill($settings->toArray());
    }

    public static function getNavigationLabel(): string
    {
        return __('admin.navigation.resources.Contact Settings');
    }

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make(__('admin.forms.sections.Contact Information'))
                    ->columns(2)
                    ->schema([
                        Forms\Components\TextInput::make('email')
                            ->label(__('admin.forms.fields.Email'))
                            ->email()
                            ->maxLength(255),
                        Forms\Components\TextInput::make('phone')
                            ->label(__('admin.forms.fields.Phone'))
                            ->maxLength(50),
                        Forms\Components\TextInput::make('whatsapp')
                            ->label(__('admin.forms.fields.WhatsApp'))
                            ->url()
                            ->maxLength(500),
                        Forms\Components\TextInput::make('facebook')
                            ->label(__('admin.forms.fields.Facebook'))
                            ->url()
                            ->maxLength(500),
                        Forms\Components\TextInput::make('instagram')
                            ->label(__('admin.forms.fields.Instagram'))
                            ->url()
                            ->maxLength(500),
                        Forms\Components\TextInput::make('x')
                            ->label(__('admin.forms.fields.X'))
                            ->url()
                            ->maxLength(500),
                        Forms\Components\TextInput::make('website')
                            ->label(__('admin.forms.fields.Website'))
                            ->url()
                            ->maxLength(500),
                    ]),
            ])
            ->statePath('data');
    }

    public function save(): void
    {
        $state = $this->form->getState();

        $settings = ContactSetting::firstOrCreate([]);
        $settings->update($state);

        Notification::make()
            ->title(__('admin.actions.Save'))
            ->body('Contact settings updated successfully.')
            ->success()
            ->send();
    }
}
