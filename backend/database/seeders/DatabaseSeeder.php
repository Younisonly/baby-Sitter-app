<?php

namespace Database\Seeders;

use App\Models\BabysitterProfile;
use App\Models\ServiceCategory;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            CountrySeeder::class,
            CitySeeder::class,
            SpecialSkillSeeder::class,
            LanguageSeeder::class,
            CancellationPolicySeeder::class,
            AppIconSeeder::class,
        ]);
        $this->seedCategories();
        $this->seedUsers();
        $this->seedAdmin();
        $this->call([
            ChatSeeder::class,
            NotificationTemplateSeeder::class,
        ]);
    }

    private function seedCategories(): void
    {
        $categories = [
            ['key' => 'newborn', 'label' => 'Newborn', 'label_ar' => 'حديثي الولادة', 'description' => 'Specialized care for newborn babies.', 'description_ar' => 'رعاية متخصصة للأطفال حديثي الولادة.', 'icon' => 'baby', 'color' => '#2563EB', 'sort_order' => 1],
            ['key' => 'toddler', 'label' => 'Toddler', 'label_ar' => 'الأطفال الصغار', 'description' => 'Active play, feeding, and nap support.', 'description_ar' => 'لعب نشط وإطعام ودعم القيلولة.', 'icon' => 'toddler', 'color' => '#14B8A6', 'sort_order' => 2],
            ['key' => 'preschool', 'label' => 'Preschool', 'label_ar' => 'مرحلة ما قبل المدرسة', 'description' => 'Learning activities and daily routines.', 'description_ar' => 'أنشطة تعليمية وروتين يومي.', 'icon' => 'school', 'color' => '#F59E0B', 'sort_order' => 3],
            ['key' => 'special_needs', 'label' => 'Special Needs', 'label_ar' => 'احتياجات خاصة', 'description' => 'Experienced, patient care support.', 'description_ar' => 'دعم رعاية ذو خبرة وصبر.', 'icon' => 'heart', 'color' => '#DC2626', 'sort_order' => 4],
            ['key' => 'overnight', 'label' => 'Overnight', 'label_ar' => 'مبيت', 'description' => 'Evening and overnight care.', 'description_ar' => 'رعاية في المساء وخلال الليل.', 'icon' => 'moon', 'color' => '#7C3AED', 'sort_order' => 5],
            ['key' => 'emergency', 'label' => 'Emergency', 'label_ar' => 'طوارئ', 'description' => 'Fast booking for urgent needs.', 'description_ar' => 'حجز سريع للحالات العاجلة.', 'icon' => 'emergency', 'color' => '#0EA5E9', 'sort_order' => 6],
        ];

        foreach ($categories as $category) {
            ServiceCategory::updateOrCreate(['key' => $category['key']], $category);
        }
    }

    private function seedUsers(): void
    {
        $parent = User::updateOrCreate(
            ['email' => 'parent@example.com'],
            [
                'name' => 'Demo Parent',
                'phone' => '+962790000001',
                'password' => Hash::make('Password123'),
                'role' => 'babysitter',
                'location' => 'Amman, Jordan',
                'latitude' => 31.9515,
                'longitude' => 35.9255,
                'verification_status' => 'verified',
                'email_verified_at' => now(),
                'has_parent_profile' => true,
                'has_sitter_profile' => true,
                'became_sitter_at' => now(),
            ]
        );

        BabysitterProfile::updateOrCreate(
            ['user_id' => $parent->id],
            [
                'hourly_rate' => 25,
                'rating' => 4.5,
                'review_count' => 10,
                'years_experience' => 3,
                'description' => 'Demo parent also acting as a sitter for testing.',
                'categories' => ['toddler', 'preschool'],
                'certificates' => ['CPR Certified'],
                'gallery_images' => [],
                'completed_bookings' => 15,
                'cancelled_bookings' => 1,
                'total_earnings' => 375,
                'is_available' => true,
                'included_children' => 3,
                'extra_child_fee' => 5,
                'absolute_max_children' => 6,
                'availability' => [
                    ['dayOfWeek' => 1, 'startTime' => '09:00', 'endTime' => '17:00'],
                    ['dayOfWeek' => 2, 'startTime' => '09:00', 'endTime' => '17:00'],
                    ['dayOfWeek' => 3, 'startTime' => '10:00', 'endTime' => '18:00'],
                    ['dayOfWeek' => 4, 'startTime' => '09:00', 'endTime' => '17:00'],
                    ['dayOfWeek' => 5, 'startTime' => '12:00', 'endTime' => '20:00'],
                ],
            ]
        );

        User::updateOrCreate(
            ['email' => 'newparent@example.com'],
            [
                'name' => 'New Parent',
                'phone' => '+962790000002',
                'password' => Hash::make('Password123'),
                'role' => 'customer',
                'location' => 'Amman, Jordan',
                'latitude' => 31.9515,
                'longitude' => 35.9255,
                'verification_status' => 'verified',
                'email_verified_at' => now(),
                'has_parent_profile' => true,
            ]
        );

        // Pre-generated avatar references (3 sitters with images, 2 without)
        $avatars = [
            'https://images.unsplash.com/photo-1613005798967-632017e477c8?w=400&h=400&fit=crop&crop=faces&q=80&auto=format',
            'https://images.unsplash.com/photo-1613005341945-35e159e522f1?w=400&h=400&fit=crop&crop=faces&q=80&auto=format',
            'https://images.unsplash.com/photo-1599474463733-62fc9f80cffe?w=400&h=400&fit=crop&crop=faces&q=80&auto=format',
            null,
            null,
        ];

        // Remove legacy sitters replaced by the KSA sitters below
        User::whereIn('email', ['emma@example.com', 'olivia@example.com', 'sophia@example.com', 'reem@example.com'])
            ->where('role', 'babysitter')
            ->get()
            ->each(fn (User $u) => $u->delete());

        $sitters = [
            [
                'name' => 'سارة الأحمد',
                'email' => 'sara@example.com',
                'phone' => '+966550000101',
                'location' => 'الرياض، حي الملقا',
                'latitude' => 24.7743,
                'longitude' => 46.6438,
                'categories' => ['newborn', 'toddler'],
                'hourly_rate' => 60,
                'rating' => 4.9,
                'review_count' => 132,
                'years_experience' => 7,
                'completed_bookings' => 195,
                'description' => 'مربية أطفال معتمدة متخصصة في رعاية حديثي الولادة والرضع، مع خبرة في الروتين الهادئ والأنشطة الإبداعية.',
                'certificates' => ['شهادة CPR', 'إسعافات أولية', 'تنمية الطفل'],
                'languages' => ['Arabic', 'English'],
            ],
            [
                'name' => 'نورة القحطاني',
                'email' => 'noura@example.com',
                'phone' => '+966550000102',
                'location' => 'جدة، حي الروضة',
                'latitude' => 21.5499,
                'longitude' => 39.1726,
                'categories' => ['preschool', 'overnight'],
                'hourly_rate' => 70,
                'rating' => 4.8,
                'review_count' => 98,
                'years_experience' => 6,
                'completed_bookings' => 147,
                'description' => 'مربية دافئة بخبرة في التعليم المبكر ومرونة في العمل المسائي، متاحة للمبيت والعطلات.',
                'certificates' => ['التعليم المبكر', 'إسعافات أولية'],
                'languages' => ['Arabic', 'English'],
            ],
            [
                'name' => 'أمل العتيبي',
                'email' => 'amal@example.com',
                'phone' => '+966550000103',
                'location' => 'الدمام، حي الشاطئ',
                'latitude' => 26.4468,
                'longitude' => 50.1078,
                'categories' => ['special_needs', 'toddler'],
                'hourly_rate' => 80,
                'rating' => 4.95,
                'review_count' => 156,
                'years_experience' => 9,
                'completed_bookings' => 238,
                'description' => 'مربية صبورة ومنظمة بخبرة واسعة في رعاية ذوي الاحتياجات الخاصة وتدريب قوي على السلامة.',
                'certificates' => ['رعاية ذوي الاحتياجات الخاصة', 'شهادة CPR', 'تغذية'],
                'languages' => ['Arabic', 'English'],
            ],
            [
                'name' => 'لطيفة الشهري',
                'email' => 'latifa@example.com',
                'phone' => '+966550000104',
                'location' => 'الرياض، حي العليا',
                'latitude' => 24.6903,
                'longitude' => 46.6854,
                'categories' => ['toddler', 'preschool'],
                'hourly_rate' => 55,
                'rating' => 4.7,
                'review_count' => 64,
                'years_experience' => 4,
                'completed_bookings' => 89,
                'description' => 'مربية نشيطة محبة للأطفال، متخصصة في الأنشطة التعليمية واللعب التفاعلي للأطفال الصغار.',
                'certificates' => ['إسعافات أولية', 'تنمية الطفل'],
                'languages' => ['Arabic'],
            ],
            [
                'name' => 'هدى المطيري',
                'email' => 'huda@example.com',
                'phone' => '+966550000105',
                'location' => 'جدة، حي الشاطئ',
                'latitude' => 21.6144,
                'longitude' => 39.1124,
                'categories' => ['newborn', 'overnight'],
                'hourly_rate' => 65,
                'rating' => 4.85,
                'review_count' => 77,
                'years_experience' => 5,
                'completed_bookings' => 112,
                'description' => 'مربية هادئة ومتفانية في رعاية الأطفال حديثي الولادة مع خبرة في المبيت ورعاية ما بعد الولادة.',
                'certificates' => ['شهادة CPR', 'رعاية حديثي الولادة'],
                'languages' => ['Arabic'],
            ],
        ];

        foreach ($sitters as $i => $data) {
            $avatar = $avatars[$i] ?? null;
            $user = User::updateOrCreate(
                ['email' => $data['email']],
                [
                    'name' => $data['name'],
                    'phone' => $data['phone'],
                    'password' => Hash::make('Password123'),
                    'role' => 'babysitter',
                    'location' => $data['location'],
                    'latitude' => $data['latitude'],
                    'longitude' => $data['longitude'],
                    'languages' => $data['languages'],
                    'avatar' => $avatar,
                    'verification_status' => 'verified',
                    'email_verified_at' => now(),
                    'has_parent_profile' => true,
                    'has_sitter_profile' => true,
                    'became_parent_at' => now(),
                    'became_sitter_at' => now(),
                ]
            );

            $user->parentProfile()->firstOrCreate([]);

            BabysitterProfile::updateOrCreate(
                ['user_id' => $user->id],
                [
                    'hourly_rate' => $data['hourly_rate'],
                    'rating' => $data['rating'],
                    'review_count' => $data['review_count'],
                    'years_experience' => $data['years_experience'],
                    'description' => $data['description'],
                    'categories' => $data['categories'],
                    'certificates' =>                 $data['certificates'],
                    'gallery_images' => [],
                    'completed_bookings' => $data['completed_bookings'],
                    'cancelled_bookings' => 2,
                    'total_earnings' => $data['completed_bookings'] * $data['hourly_rate'],
                    'is_available' => true,
                    'included_children' => 4,
                    'extra_child_fee' => 10,
                    'absolute_max_children' => 8,
                    'availability' => [
                        ['dayOfWeek' => 1, 'startTime' => '09:00', 'endTime' => '17:00'],
                        ['dayOfWeek' => 2, 'startTime' => '09:00', 'endTime' => '17:00'],
                        ['dayOfWeek' => 3, 'startTime' => '10:00', 'endTime' => '18:00'],
                        ['dayOfWeek' => 4, 'startTime' => '09:00', 'endTime' => '17:00'],
                        ['dayOfWeek' => 5, 'startTime' => '12:00', 'endTime' => '20:00'],
                    ],
                ]
            );
        }
    }

    private function seedAdmin(): void
    {
        User::updateOrCreate(
            ['email' => 'admin@babysitter.com'],
            [
                'name' => 'System Admin',
                'phone' => '+962790000999',
                'password' => Hash::make('AdminPass123'),
                'role' => 'admin',
                'location' => 'Amman, Jordan',
                'verification_status' => 'verified',
                'email_verified_at' => now(),
            ]
        );
    }
}
