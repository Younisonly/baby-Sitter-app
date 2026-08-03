<?php

namespace App\Filament\Widgets;

use App\Models\BabysitterProfile;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget as BaseWidget;

class TopSittersTable extends BaseWidget
{
    protected static ?string $heading = 'Top Rated Babysitters';
    protected static ?int $sort = 4;
    protected int | string | array $columnSpan = 'full';

    public function getHeading(): string
    {
        return __('admin.dashboard.Top Rated Babysitters');
    }

    public function table(Table $table): Table
    {
        return $table
            ->query(
                BabysitterProfile::query()
                    ->with('user')
                    ->orderByDesc('rating')
                    ->orderByDesc('completed_bookings')
                    ->limit(5)
            )
            ->columns([
                Tables\Columns\TextColumn::make('user.name')
                    ->label(__('admin.forms.fields.Name'))
                    ->searchable(),
                Tables\Columns\TextColumn::make('hourly_rate')
                    ->label(__('admin.forms.fields.Hourly Rate'))
                    ->money('USD'),
                Tables\Columns\TextColumn::make('rating')
                    ->label(__('admin.forms.fields.Rating'))
                    ->numeric(2)
                    ->icon('heroicon-s-star')
                    ->iconColor('warning'),
                Tables\Columns\TextColumn::make('completed_bookings')
                    ->label(__('admin.forms.fields.Completed Bookings'))
                    ->numeric(),
                Tables\Columns\TextColumn::make('total_earnings')
                    ->label(__('admin.forms.fields.Total Earnings'))
                    ->money('USD'),
                Tables\Columns\IconColumn::make('is_available')
                    ->label(__('admin.forms.fields.Available'))
                    ->boolean(),
            ])
            ->paginated(false);
    }
}
