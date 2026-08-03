<?php
namespace App\Filament\Widgets;

use App\Models\User;
use App\Models\Booking;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;
use Illuminate\Database\Eloquent\Builder;

class StatsOverview extends BaseWidget
{
    protected function getStats(): array
    {
        return [
            Stat::make(__('admin.dashboard.Total Users'), User::count())
                ->description(User::whereDate('created_at', today())->count() . ' ' . __('admin.dashboard.today'))
                ->descriptionIcon('heroicon-m-users')
                ->color('primary')
                ->chart($this->dailySeries(User::query())),

            Stat::make(__('admin.dashboard.Babysitters'), User::where('role', 'babysitter')->count())
                ->description(User::where('role', 'babysitter')->where('verification_status', 'verified')->count() . ' ' . __('admin.dashboard.verified'))
                ->descriptionIcon('heroicon-m-briefcase')
                ->color('success')
                ->chart($this->dailySeries(User::query()->where('role', 'babysitter'))),

            Stat::make(__('admin.dashboard.Parents'), User::where('role', 'customer')->count())
                ->description(User::where('role', 'customer')->whereDate('created_at', '>=', now()->subWeek())->count() . ' ' . __('admin.dashboard.new this week'))
                ->descriptionIcon('heroicon-m-user-group')
                ->color('info')
                ->chart($this->dailySeries(User::query()->where('role', 'customer'))),

            Stat::make(__('admin.dashboard.Total Bookings'), Booking::count())
                ->description(Booking::where('status', 'completed')->count() . ' ' . __('admin.dashboard.completed'))
                ->descriptionIcon('heroicon-m-calendar-days')
                ->color('secondary')
                ->chart($this->dailySeries(Booking::query())),

            Stat::make(__('admin.dashboard.Pending Verifications'), User::where('role', 'babysitter')->where('verification_status', 'under_review')->count())
                ->description(User::where('verification_status', 'unverified')->where('role', 'babysitter')->count() . ' ' . __('admin.dashboard.unverified sitters'))
                ->descriptionIcon('heroicon-m-clock')
                ->color('warning')
                ->chart($this->dailySeries(User::query()->where('role', 'babysitter')->where('verification_status', 'under_review'))),

            Stat::make(__('admin.dashboard.Revenue'), '$' . number_format((float) Booking::where('status', 'completed')->sum('total_amount'), 2))
                ->description(__('admin.dashboard.Total completed booking value'))
                ->descriptionIcon('heroicon-m-currency-dollar')
                ->color('success')
                ->chart($this->dailySeries(Booking::query()->where('status', 'completed'), 'created_at', 'total_amount')),

            Stat::make(__('admin.dashboard.Active Sessions'), Booking::where('status', 'in_progress')->count())
                ->description(__('admin.dashboard.Currently active babysitting sessions'))
                ->descriptionIcon('heroicon-m-play-circle')
                ->color('primary')
                ->chart($this->dailySeries(Booking::query()->where('status', 'in_progress'))),
        ];
    }

    /**
     * Build a 7-day (last 6 days + today) trend series for a stat card.
     * Counts rows per day, or sums $sumColumn when provided (e.g. revenue).
     */
    private function dailySeries(Builder $query, string $dateColumn = 'created_at', ?string $sumColumn = null): array
    {
        $rows = (clone $query)
            ->where($dateColumn, '>=', now()->subDays(6)->startOfDay())
            ->selectRaw("DATE($dateColumn) as day" . ($sumColumn ? ", SUM($sumColumn) as total" : ", COUNT(*) as total"))
            ->groupBy('day')
            ->pluck('total', 'day');

        return collect(range(6, 0))
            ->map(fn (int $daysAgo): float => (float) ($rows[now()->subDays($daysAgo)->toDateString()] ?? 0))
            ->values()
            ->all();
    }
}
