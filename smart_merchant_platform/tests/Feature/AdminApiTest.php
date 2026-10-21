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
            ->assertJsonPath('data.total_businesses', 1)
            ->assertJsonStructure(['data' => ['total_businesses', 'total_users', 'total_orders', 'total_devices', 'accounts']]);
    }

    public function test_admin_can_manage_accounts()
    {
        $adminAccount = Account::factory()->create();
        $admin = User::factory()->create(['account_id' => $adminAccount->id]);

        $targetAccount = Account::factory()->create(['status' => 'Suspended']);

        // List accounts
        $this->actingAs($admin)->getJson('/api/admin/v1/accounts')
            ->assertStatus(200)
            ->assertJsonStructure(['data' => [['id', 'name', 'status']]]);

        // Approve / Reactivate
        $this->actingAs($admin)->postJson("/api/admin/v1/accounts/{$targetAccount->id}/approve")
            ->assertStatus(200)
            ->assertJsonPath('data.status', 'Active');

        // Suspend
        $this->actingAs($admin)->postJson("/api/admin/v1/accounts/{$targetAccount->id}/suspend")
            ->assertStatus(200)
            ->assertJsonPath('data.status', 'Suspended');
    }

    public function test_admin_can_list_and_update_users()
    {
        $account = Account::factory()->create();
        $admin = User::factory()->create(['account_id' => $account->id]);
        $targetUser = User::factory()->create(['account_id' => $account->id, 'is_active' => true]);

        // List users
        $this->actingAs($admin)->getJson('/api/admin/v1/users')
            ->assertStatus(200)
            ->assertJsonStructure(['data' => [['id', 'email', 'is_active']]]);

        // Toggle user status
        $this->actingAs($admin)->putJson("/api/admin/v1/users/{$targetUser->id}", ['is_active' => false])
            ->assertStatus(200)
            ->assertJsonPath('data.is_active', false);
    }

    public function test_admin_can_create_complete_customer_account_matching_flutter_fields()
    {
        $adminAccount = Account::factory()->create();
        $admin = User::factory()->create(['account_id' => $adminAccount->id]);

        $payload = [
            'first_name' => 'سامي',
            'last_name' => 'الحداد',
            'username' => 'samielhaddad',
            'email' => 'sami@example.com',
            'phone' => '+967770001122',
            'password' => 'secret123456',
            'business_name' => 'مؤسسة الحداد التجارية',
            'business_type' => 'retail',
            'primary_phone' => '+967770001122',
            'primary_email' => 'business@example.com',
            'country' => 'اليمن',
            'city' => 'صنعاء',
            'address' => 'شارع حدة، مبنى النخبة',
            'currency' => 'YER',
        ];

        $response = $this->actingAs($admin)->postJson('/api/admin/v1/accounts', $payload);

        $response->assertStatus(201)
            ->assertJsonPath('data.user.email', 'sami@example.com')
            ->assertJsonPath('data.user.username', 'samielhaddad')
            ->assertJsonPath('data.business.business_name', 'مؤسسة الحداد التجارية')
            ->assertJsonPath('data.business.business_type', 'retail')
            ->assertJsonPath('data.account.status', 'Active')
            ->assertJsonPath('data.credentials.email', 'sami@example.com');

        // Verify Database State
        $this->assertDatabaseHas('accounts', [
            'email' => 'sami@example.com',
            'status' => 'Active',
        ]);
        $this->assertDatabaseHas('businesses', [
            'business_name' => 'مؤسسة الحداد التجارية',
            'business_type' => 'retail',
            'status' => 'Active',
        ]);
        $this->assertDatabaseHas('branches', [
            'branch_code' => 'MAIN',
            'is_active' => true,
        ]);
        $this->assertDatabaseHas('users', [
            'email' => 'sami@example.com',
            'username' => 'samielhaddad',
            'is_active' => true,
        ]);

        $createdUser = User::where('email', 'sami@example.com')->first();
        $this->assertNotNull($createdUser);
        $this->assertTrue(Hash::check('secret123456', $createdUser->password_hash));
        $this->assertNotNull($createdUser->default_branch_id);

        // Immediate Mobile Customer Login Verification
        $loginResponse = $this->postJson('/api/auth/login', [
            'email' => 'sami@example.com',
            'password' => 'secret123456',
            'device_name' => 'flutter-android-test',
        ]);

        $loginResponse->assertStatus(200)
            ->assertJsonPath('user.email', 'sami@example.com')
            ->assertJsonStructure(['token', 'user']);

        $token = $loginResponse->json('token');

        $u = User::where('email', 'sami@example.com')->first();
        // Reset actingAs state so the request authenticates via Sanctum token
        auth('sanctum')->forgetUser();
        $this->app['auth']->forgetGuards();

        // Immediate Session Bootstrap Verification (used by Flutter client upon login)
        $bootstrapResponse = $this->withToken($token)->getJson('/api/session/bootstrap');
        $bootstrapResponse->assertStatus(200)
            ->assertJsonPath('user.email', 'sami@example.com')
            ->assertJsonPath('active_business.business_name', 'مؤسسة الحداد التجارية')
            ->assertJsonPath('active_business.business_type', 'retail')
            ->assertJsonPath('active_branch.branch_code', 'MAIN');
    }

    public function test_create_account_validates_required_flutter_fields()
    {
        $adminAccount = Account::factory()->create();
        $admin = User::factory()->create(['account_id' => $adminAccount->id]);

        $response = $this->actingAs($admin)->postJson('/api/admin/v1/accounts', []);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['first_name', 'last_name', 'username', 'email', 'password', 'business_name', 'business_type']);
    }

    public function test_create_account_rejects_duplicate_email()
    {
        $adminAccount = Account::factory()->create();
        $admin = User::factory()->create(['account_id' => $adminAccount->id]);

        $existingUser = User::factory()->create(['email' => 'existing@example.com']);

        $response = $this->actingAs($admin)->postJson('/api/admin/v1/accounts', [
            'first_name' => 'Test',
            'last_name' => 'User',
            'username' => 'testuser999',
            'email' => 'existing@example.com',
            'password' => 'password123',
            'business_name' => 'My Shop',
            'business_type' => 'retail',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    public function test_unauthenticated_user_cannot_create_account()
    {
        $response = $this->postJson('/api/admin/v1/accounts', [
            'first_name' => 'Test',
            'last_name' => 'User',
            'username' => 'testuser999',
            'email' => 'test@example.com',
            'password' => 'password123',
            'business_name' => 'My Shop',
            'business_type' => 'retail',
        ]);

        $response->assertStatus(401);
    }
}

