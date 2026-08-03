<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AppIcon extends Model
{
    protected $fillable = [
        'key',
        'label',
        'label_ar',
        'category',
        'family',
        'keywords',
        'is_active',
        'sort_order',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeByCategory($query, string $category)
    {
        return $query->where('category', $category);
    }

    public function scopeOrdered($query)
    {
        return $query->orderBy('sort_order')->orderBy('label');
    }

    public static function categories(): array
    {
        return [
            'childcare' => 'Childcare',
            'booking' => 'Booking & Calendar',
            'communication' => 'Communication',
            'security' => 'Security',
            'navigation' => 'Navigation & UI',
            'profile' => 'Profile & People',
            'status' => 'Status & Alerts',
            'payment' => 'Payment & Finance',
            'notifications' => 'Notifications',
            'reviews' => 'Reviews & Ratings',
            'location' => 'Location & Maps',
            'activities' => 'Activities & Analytics',
            'media' => 'Media & Files',
            'support' => 'Support & Help',
            'actions' => 'Actions',
            'certificates' => 'Certificates & Education',
            'admin' => 'Admin & Management',
        ];
    }

    public static function categoriesAr(): array
    {
        return [
            'childcare' => 'رعاية الأطفال',
            'booking' => 'الحجز والتقويم',
            'communication' => 'التواصل',
            'security' => 'الأمان',
            'navigation' => 'التنقل والواجهة',
            'profile' => 'الملف الشخصي والأشخاص',
            'status' => 'الحالة والتنبيهات',
            'payment' => 'الدفع والمالية',
            'notifications' => 'الإشعارات',
            'reviews' => 'التقييمات',
            'location' => 'الموقع والخرائط',
            'activities' => 'النشاطات والتحليلات',
            'media' => 'الوسائط والملفات',
            'support' => 'الدعم والمساعدة',
            'actions' => 'إجراءات',
            'certificates' => 'الشهادات والتعليم',
            'admin' => 'الإدارة',
        ];
    }
}
