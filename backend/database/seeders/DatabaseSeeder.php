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

        // Pre-generated avatar references
        $avatars = [
            '/storage/uploads/avatars/avatar_2_8YCv3Wua.jpg',
            'https://i.pravatar.cc/400?u=olivia@example.com',
            'https://i.pravatar.cc/400?u=sophia@example.com',
        ];

        $sitters = [
            [
                'name' => 'Emma Wilson',
                'email' => 'emma@example.com',
                'phone' => '+962790000101',
                'location' => 'Abdoun, Amman',
                'latitude' => 31.9565,
                'longitude' => 35.8843,
                'categories' => ['newborn', 'toddler'],
                'hourly_rate' => 24,
                'rating' => 4.9,
                'review_count' => 128,
                'years_experience' => 6,
                'completed_bookings' => 184,
                'description' => 'Certified childcare provider focused on calm routines, creative play, and clear parent communication.',
                'certificates' => ['CPR Certified', 'First Aid', 'Child Development'],
            ],
            [
                'name' => 'Olivia Brown',
                'email' => 'olivia@example.com',
                'phone' => '+962790000102',
                'location' => 'Jabal Amman',
                'latitude' => 31.9497,
                'longitude' => 35.9290,
                'categories' => ['preschool', 'overnight'],
                'hourly_rate' => 28,
                'rating' => 4.8,
                'review_count' => 96,
                'years_experience' => 5,
                'completed_bookings' => 142,
                'description' => 'Warm sitter with early education experience and flexible evening availability.',
                'certificates' => ['Early Education', 'First Aid'],
            ],
            [
                'name' => 'Sophia Davis',
                'email' => 'sophia@example.com',
                'phone' => '+962790000103',
                'location' => 'Swefieh',
                'latitude' => 31.9620,
                'longitude' => 35.8730,
                'categories' => ['special_needs', 'toddler'],
                'hourly_rate' => 32,
                'rating' => 4.95,
                'review_count' => 151,
                'years_experience' => 8,
                'completed_bookings' => 231,
                'description' => 'Patient, structured caregiver with special needs experience and strong safety training.',
                'certificates' => ['Special Needs Care', 'CPR Certified', 'Nutrition'],
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
                    'languages' => ['English', 'Arabic'],
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
                    'extra_child_fee' => 5,
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
