<?php

namespace Tests\Feature;

use App\Models\User;
use Tests\TestCase;

class AdminSideNavTest extends TestCase
{
    private function makeAdmin(): User
    {
        User::where('email', 'like', 'navdebug@%')->delete();

        return User::create([
            'name' => 'Nav Debug Admin',
            'email' => 'navdebug@babysitter.com',
            'phone' => '01000000000',
            'password' => bcrypt('Password123'),
            'role' => 'super_admin',
            'is_verified' => true,
            'phone_verified_at' => now(),
        ]);
    }

    private function outFile(): string
    {
        return storage_path('app/nav_%s.json');
    }

    private function renderAndSave(string $locale, string $fileKey): void
    {
        $admin = $this->makeAdmin();
        $this->actingAs($admin)->get('/admin/locale/' . $locale);
        $html = $this->get('/admin')->getContent();

        preg_match_all('/data-group-label="([^"]*)"/', $html, $g);
        preg_match_all('/class="fi-sidebar-item-label[^"]*"[^>]*>(.*?)</s', $html, $i);

        $out = [
            'groups' => array_map(fn ($x) => trim(strip_tags($x)), $g[1]),
            'items' => array_map(fn ($x) => trim(strip_tags($x)), $i[1]),
        ];
        file_put_contents(sprintf($this->outFile(), $fileKey), json_encode($out));
        $admin->forceDelete();
    }

    public function test_en_output(): void
    {
        $this->renderAndSave('en', 'en');
        $this->assertTrue(true);
    }

    public function test_ar_output(): void
    {
        $this->renderAndSave('ar', 'ar');
        $this->assertTrue(true);
    }

    public function test_compare_en_ar(): void
    {
        $en = json_decode(file_get_contents(sprintf($this->outFile(), 'en')), true);
        $ar = json_decode(file_get_contents(sprintf($this->outFile(), 'ar')), true);

        fwrite(STDERR, "\n=== en ===\nGROUPS: " . implode(' | ', $en['groups']) . "\nITEMS: " . implode(' | ', $en['items']) . "\n");
        fwrite(STDERR, "=== ar ===\nGROUPS: " . implode(' | ', $ar['groups']) . "\nITEMS: " . implode(' | ', $ar['items']) . "\n");

        $this->assertSame($en['groups'], $this->toEnSemantics($ar['groups'], 'groups'), 'Group order differs.');
        $this->assertSame($en['items'], $this->toEnSemantics($ar['items'], 'resources'), 'Item order differs.');
    }

    private function toEnSemantics(array $localized, string $section): array
    {
        $ar = require lang_path('ar/admin.php');
        $inverse = array_flip($ar['navigation'][$section] ?? []);
        $inverse['لوحة التحكم'] = 'Dashboard';

        return array_map(fn($v) => $inverse[$v] ?? $v, $localized);
    }
}