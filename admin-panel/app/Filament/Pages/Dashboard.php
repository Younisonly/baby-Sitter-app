<?php
namespace App\Filament\Pages;

use App\Filament\Widgets\StatsOverview;
use App\Filament\Widgets\RevenueChartWidget;
use App\Filament\Widgets\BookingStatusChart;
use App\Filament\Widgets\TopSittersTable;
use App\Filament\Widgets\LatestBookingsTable;
use App\Filament\Widgets\PendingSittersTable;
use Filament\Pages\Dashboard as BaseDashboard;

class Dashboard extends BaseDashboard
{
    public function getWidgets(): array
    {
        return [
            StatsOverview::class,
            RevenueChartWidget::class,
            BookingStatusChart::class,
            TopSittersTable::class,
            LatestBookingsTable::class,
            PendingSittersTable::class,
        ];
    }
}
