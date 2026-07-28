<?php

namespace Tests\Feature;

use App\Models\Account;
use App\Models\Business;
use App\Models\User;
use App\Models\Branch;
use App\Models\Role;
use App\Models\Device;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AdminApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
    }

    public function test_unauthenticated_access_is_rejected()
    {
        $response = $this->getJson('/api/admin/v1/me');
        $response->assertStatus(401);
    }

    public function test_admin_me_endpoint_returns_context()
    {
        $account = Account::factory()->create();
        $user = User::factory()->create(['account_id' => $account->id]);
        
        $response = $this->actingAs($user)->getJson('/api/admin/v1/me');
        
        $response->assertStatus(200)
            ->assertJsonPath('data.email', $user->email)
            ->assertJsonPath('data.account.id', $account->id);
    }

    public function test_admin_business_list_is_tenant_scoped()
    {
        $account1 = Account::factory()->create();
        $user1 = User::factory()->create(['account_id' => $account1->id]);
        $business1 = Business::factory()->create(['account_id' => $account1->id]);

        $account2 = Account::factory()->create();
        $user2 = User::factory()->create(['account_id' => $account2->id]);
        $business2 = Business::factory()->create(['account_id' => $account2->id]);

        // User 1 sees Business 1
        $this->actingAs($user1)->getJson('/api/admin/v1/businesses')
            ->assertStatus(200)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $business1->id);

        // User 1 cannot access Business 2 explicitly
        $this->actingAs($user1)->getJson("/api/admin/v1/businesses/{$business2->id}")
            ->assertStatus(404);
    }

    public function test_cross_tenant_branch_access_is_rejected()
    {
        $account1 = Account::factory()->create();
        $user1 = User::factory()->create(['account_id' => $account1->id]);
        $business1 = Business::factory()->create(['account_id' => $account1->id]);

        $account2 = Account::factory()->create();
        $business2 = Business::factory()->create(['account_id' => $account2->id]);

        // Accessing branch via a business the user does not own
        $this->actingAs($user1)->getJson("/api/admin/v1/businesses/{$business2->id}/branches")
            ->assertStatus(403);
    }

    public function test_admin_can_create_user_for_business()
    {
        $account = Account::factory()->create();
        $user = User::factory()->create(['account_id' => $account->id]);
        $business = Business::factory()->create(['account_id' => $account->id]);
        
        $payload = [
            'username' => 'newadmin',
            'email' => 'newadmin@example.com',
            'password' => 'securepassword123',
            'full_name' => 'New Admin',
        ];

        $this->actingAs($user)->postJson("/api/admin/v1/businesses/{$business->id}/users", $payload)
            ->assertStatus(201)
            ->assertJsonPath('data.username', 'newadmin');
            
        $this->assertDatabaseHas('users', ['email' => 'newadmin@example.com', 'account_id' => $account->id]);
    }

    public function test_admin_can_revoke_device()
    {
        $account = Account::factory()->create();
        $user = User::factory()->create(['account_id' => $account->id]);
        $business = Business::factory()->create(['account_id' => $account->id]);
        $device = Device::factory()->create(['business_id' => $business->id, 'user_id' => $user->id]);

        $this->actingAs($user)->deleteJson("/api/admin/v1/businesses/{$business->id}/devices/{$device->id}")
            ->assertStatus(200);

        $this->assertNotNull($device->fresh()->revoked_at);
    }

    public function test_privilege_escalation_is_blocked_for_cross_tenant_assignment()
    {
        $account1 = Account::factory()->create();
        $user1 = User::factory()->create(['account_id' => $account1->id]);
        $business1 = Business::factory()->create(['account_id' => $account1->id]);

        $account2 = Account::factory()->create();
        $business2 = Business::factory()->create(['account_id' => $account2->id]);
        $role2 = Role::factory()->create(['business_id' => $business2->id]);

        $payload = [
            'username' => 'attacker',
            'email' => 'attacker@example.com',
            'password' => 'password123',
            'full_name' => 'Attacker',
            'role_ids' => [$role2->id], // Attempting to assign a role from another business
        ];

        $this->actingAs($user1)->postJson("/api/admin/v1/businesses/{$business1->id}/users", $payload)
            ->assertStatus(422)
            ->assertJsonValidationErrors(['role_ids.0']);
    }

    public function test_admin_dashboard_returns_aggregate_data()
    {
        $account = Account::factory()->create();
        $user = User::factory()->create(['account_id' => $account->id]);
        $business = Business::factory()->create(['account_id' => $account->id]);

        $response = $this->actingAs($user)->getJson('/api/admin/v1/dashboard');
        
        $response->assertStatus(200)
            ->assertJsonPath('data.total_businesses', 1);
    }
}
