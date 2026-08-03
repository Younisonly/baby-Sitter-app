<?php
namespace App\Filament\Widgets;

use App\Models\Booking;
use Filament\Widgets\ChartWidget;

class BookingStatusChart extends ChartWidget
{
    protected static ?string $heading = 'Bookings by Status';
    protected static ?int $sort = 1;

    public function getHeading(): string
    {
        return __('admin.dashboard.Bookings by Status');
    }

    protected function getData(): array
    {
        $pending = Booking::where('status', 'pending')->count();
        $confirmed = Booking::where('status', 'confirmed')->count();
        $inProgress = Booking::where('status', 'in_progress')->count();
        $completed = Booking::where('status', 'completed')->count();
        $cancelled = Booking::where('status', 'cancelled')->count();
        $rejected = Booking::where('status', 'rejected')->count();

        $statusCounts = [
            __('admin.booking_status.pending') => $pending,
            __('admin.booking_status.confirmed') => $confirmed,
            __('admin.booking_status.in_progress') => $inProgress,
            __('admin.booking_status.completed') => $completed,
            __('admin.booking_status.cancelled') => $cancelled,
            __('admin.booking_status.rejected') => $rejected,
        ];

        return [
            'datasets' => [
                [
                    'label' => __('admin.dashboard.Bookings by Status'),
                    'data' => array_values($statusCounts),
                    'backgroundColor' => ['#F59E0B', '#38BDF8', '#2CA6A4', '#22C55E', '#EF4444', '#6B7280'],
                ],
            ],
            'labels' => array_keys($statusCounts),
        ];
    }

    protected function getType(): string
    {
        return 'doughnut';
    }

    protected function getOptions(): array
    {
        return [
            'plugins' => [
                'legend' => [
                    'position' => 'bottom',
                ],
            ],
        ];
    }
}
