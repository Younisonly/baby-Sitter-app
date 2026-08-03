<?php
namespace App\Filament\Widgets;

use App\Models\Booking;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget as BaseWidget;

class LatestBookingsTable extends BaseWidget
{
    protected static ?string $heading = 'Latest Bookings';
    protected static ?int $sort = 2;
    protected int | string | array $columnSpan = 'full';

    public function getHeading(): string
    {
        return __('admin.dashboard.Latest Bookings');
    }

    public function table(Table $table): Table
    {
        return $table
            ->query(
                Booking::query()->latest()->limit(10)
            )
            ->columns([
                Tables\Columns\TextColumn::make('booking_number')
                    ->searchable(),
                Tables\Columns\TextColumn::make('customer.name')
                    ->searchable(),
                Tables\Columns\TextColumn::make('sitter.name')
                    ->searchable(),
                Tables\Columns\TextColumn::make('date')
                    ->date()
                    ->sortable(),
                Tables\Columns\TextColumn::make('total_amount')
                    ->money('USD')
                    ->sortable(),
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->formatStateUsing(fn (string $state): string => __("admin.booking_status.{$state}"))
                    ->color(fn (string $state): string => match ($state) {
                        'pending' => 'warning',
                        'confirmed' => 'info',
                        'in_progress' => 'primary',
                        'completed' => 'success',
                        'cancelled' => 'danger',
                        'rejected' => 'gray',
                        'expired' => 'dark',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(),
            ])
            ->poll('10s');
    }
}
