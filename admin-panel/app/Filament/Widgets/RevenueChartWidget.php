<?php

namespace App\Filament\Widgets;

use App\Models\Booking;
use Filament\Widgets\ChartWidget;
use Illuminate\Support\Carbon;

class RevenueChartWidget extends ChartWidget
{
    protected static ?string $heading = 'Revenue & Booking Trends';
    protected static ?int $sort = 2;
    protected int | string | array $columnSpan = 'full';

    public function getHeading(): string
    {
        return __('admin.dashboard.Revenue & Booking Trends');
    }

    protected function getData(): array
    {
        $months = collect(range(5, 0))->map(function ($i) {
            return Carbon::now()->subMonths($i);
        });

        $labels = $months->map(fn ($date) => $date->format('M Y'))->toArray();

        $revenueData = $months->map(function ($date) {
            return Booking::where('status', 'completed')
                ->whereYear('created_at', $date->year)
                ->whereMonth('created_at', $date->month)
                ->sum('total_amount');
        })->toArray();

        $bookingsData = $months->map(function ($date) {
            return Booking::whereYear('created_at', $date->year)
                ->whereMonth('created_at', $date->month)
                ->count();
        })->toArray();

        return [
            'datasets' => [
                [
                    'label' => __('admin.dashboard.Revenue ($)'),
                    'data' => $revenueData,
                    'borderColor' => '#22C55E',
                    'backgroundColor' => 'rgba(34, 197, 94, 0.1)',
                    'fill' => true,
                ],
                [
                    'label' => __('admin.dashboard.Total Bookings'),
                    'data' => $bookingsData,
                    'borderColor' => '#2CA6A4',
                    'backgroundColor' => 'rgba(44, 166, 164, 0.1)',
                    'fill' => true,
                ],
            ],
            'labels' => $labels,
        ];
    }

    protected function getType(): string
    {
        return 'line';
    }
}
