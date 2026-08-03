<?php
namespace App\Filament\Widgets;

use App\Models\User;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget as BaseWidget;

class PendingSittersTable extends BaseWidget
{
    protected static ?string $heading = 'Pending Sitters';
    protected static ?int $sort = 3;
    protected int | string | array $columnSpan = 'full';

    public function getHeading(): string
    {
        return __('admin.dashboard.Pending Sitters');
    }

    public function table(Table $table): Table
    {
        return $table
            ->query(
                User::where('role', 'babysitter')
                    ->whereIn('verification_status', ['under_review', 'unverified'])
                    ->latest()
                    ->limit(10)
            )
            ->columns([
                Tables\Columns\TextColumn::make('name')
                    ->searchable(),
                Tables\Columns\TextColumn::make('email')
                    ->searchable(),
                Tables\Columns\TextColumn::make('phone')
                    ->searchable(),
                Tables\Columns\TextColumn::make('verification_status')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => __("admin.verification_status.{$state}"))
                    ->color(fn (string $state): string => match ($state) {
                        'verified' => 'success',
                        'under_review' => 'warning',
                        'rejected' => 'danger',
                        'unverified' => 'gray',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable(),
            ])
            ->actions([
                Tables\Actions\Action::make('verify')
                    ->label(__('admin.actions.Verify'))
                    ->action(fn (User $record) => $record->update(['verification_status' => 'verified']))
                    ->color('success')
                    ->icon('heroicon-o-check-circle')
                    ->requiresConfirmation(),
                Tables\Actions\Action::make('reject')
                    ->label(__('admin.actions.Reject'))
                    ->action(fn (User $record) => $record->update(['verification_status' => 'rejected']))
                    ->color('danger')
                    ->icon('heroicon-o-x-circle')
                    ->requiresConfirmation(),
            ])
            ->poll('30s');
    }
}
