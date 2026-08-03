<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class AdminPanelAccessTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        config(['database.default' => 'mysql']);
        config(['database.connections.mysql.database' => 'babysitter']);
        DB::purge('mysql');
    }

    public function test_guest_is_redirected_from_panel(): void
    {
        $this->get('/admin/users')->assertRedirect();
    }

    public function test_super_admin_can_view_users_page(): void
    {
        $super = User::where('email', 'superadmin@babysitter.com')->firstOrFail();
        $this->actingAs($super);
        $this->get('/admin/users')->assertSuccessful();
    }

    public function test_normal_admin_can_view_users_page(): void
    {
        $admin = User::where('email', 'admin@babysitter.com')->firstOrFail();
        $this->actingAs($admin);
        $this->get('/admin/users')->assertSuccessful();
    }

    public function test_customer_cannot_access_panel(): void
    {
        $customer = User::where('email', 'parent@example.com')->first();
        if (! $customer) {
            $this->markTestSkipped('Demo parent not seeded locally.');
        }
        $this->actingAs($customer);
        $this->get('/admin/users')->assertForbidden();
    }

    public function test_super_admin_can_open_create_admin_page(): void
    {
        $super = User::where('email', 'superadmin@babysitter.com')->firstOrFail();
        $this->actingAs($super);
        $this->get('/admin/users/create-admin')->assertSuccessful();
    }

    public function test_users_table_header_shows_both_buttons_for_super_admin(): void
    {
        $super = User::where('email', 'superadmin@babysitter.com')->firstOrFail();
        $this->actingAs($super);
        $response = $this->get('/admin/users');
        $response->assertSuccessful();
        $this->assertStringContainsString('New user', $response->getContent());
        $this->assertStringContainsString('Create Admin', $response->getContent());
    }

    public function test_normal_admin_cannot_open_create_admin_page(): void
    {
        $admin = User::where('email', 'admin@babysitter.com')->firstOrFail();
        $this->actingAs($admin);
        $this->get('/admin/users/create-admin')->assertForbidden();
    }
}
