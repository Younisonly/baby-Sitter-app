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

    /**
     * @return array{groups: string[], items: string[]}
     */
private function renderSidebar(string $locale): array
    {
        $this->refreshApplication();
        $admin = $this->makeAdmin();
        $this->actingAs($admin)->withSession(['admin_locale' => $locale]);
        $response = $this->get('/admin');
        $html = $response->getContent();
        $admin->forceDelete();

        preg_match_all('/data-group-label="([^"]*)"/', $html, $groups);
        preg_match_all('/class="fi-sidebar-item-label[^"]*"[^>]*>(.*?)</s', $html, $items);

        return [
            'groups' => array_map(fn (string $x): string => trim(strip_tags($x)), $groups[1]),
            'items' => array_map(fn (string $x): string => trim(strip_tags($x)), $items[1]),
        ];
    }

    /**
     * Map localized sidebar labels back to their English (EN) keys so that
     * AR and EN renderings can be compared positionally.
     *
     * @param  string[]  $localized
     * @return string[]
     */
    private function toEnSemantics(array $localized, string $section): array
    {
        $ar = require lang_path('ar/admin.php');
        $inverse = array_flip($ar['navigation'][$section] ?? []);
        $inverse['لوحة التحكم'] = 'Dashboard';

        return array_map(fn (string $value): string => $inverse[$value] ?? $value, $localized);
    }

    public function test_sidebar_group_and_item_order_is_identical_in_en_and_ar(): void
    {
        $en = $this->renderSidebar('en');
        $ar = $this->renderSidebar('ar');

        $mappedArGroups = $this->toEnSemantics($ar['groups'], 'groups');
        $mappedArItems = $this->toEnSemantics($ar['items'], 'resources');

        $this->assertSame(
            $en['groups'],
            $mappedArGroups,
            'Group order differs between EN and AR.',
        );
        $this->assertSame(
            $en['items'],
            $mappedArItems,
            'Item order differs between EN and AR.',
        );
    }

    public function test_every_sidebar_item_is_localized_in_ar(): void
    {
        $ar = require lang_path('ar/admin.php');
        $allowedGroups = [...array_values($ar['navigation']['groups']), ''];
        $allowedItems = [...array_values($ar['navigation']['resources']), 'لوحة التحكم'];

        $rendered = $this->renderSidebar('ar');

        foreach ($rendered['groups'] as $label) {
            $this->assertContains($label, $allowedGroups, 'Untranslated sidebar group: ' . $label);
        }

        foreach ($rendered['items'] as $label) {
            $this->assertContains($label, $allowedItems, 'Untranslated sidebar item: ' . $label);
        }
    }
}