<?php

$testsDir = __DIR__.'/tests/Feature/Auth';
if (! is_dir($testsDir)) {
    mkdir($testsDir, 0777, true);
}

file_put_contents($testsDir.'/LoginTest.php', <<<PHP
<?php
namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class LoginTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_login_with_valid_credentials()
    {
        \$user = User::factory()->create([
            'password_hash' => Hash::make('password123'),
            'is_active' => true,
        ]);

        \$response = \$this->postJson('/api/auth/login', [
            'email' => \$user->email,
            'password' => 'password123',
            'device_name' => 'test-device'
        ]);

        \$response->assertStatus(200)
                 ->assertJsonStructure(['message', 'token', 'user']);
        
        \$this->assertNotNull(\$user->fresh()->last_login_at);
    }

    public function test_user_cannot_login_with_invalid_credentials()
    {
        \$user = User::factory()->create([
            'password_hash' => Hash::make('password123'),
        ]);

        \$response = \$this->postJson('/api/auth/login', [
            'email' => \$user->email,
            'password' => 'wrongpassword'
        ]);

        \$response->assertStatus(422);
    }

    public function test_inactive_user_cannot_login()
    {
        \$user = User::factory()->create([
            'password_hash' => Hash::make('password123'),
            'is_active' => false,
        ]);

        \$response = \$this->postJson('/api/auth/login', [
            'email' => \$user->email,
            'password' => 'password123'
        ]);

        \$response->assertStatus(422)
                 ->assertJsonFragment(['User account is inactive.']);
    }
}
PHP);

file_put_contents($testsDir.'/LogoutTest.php', <<<PHP
<?php
namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class LogoutTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_logout()
    {
        \$user = User::factory()->create();
        \$token = \$user->createToken('test')->plainTextToken;

        \$response = \$this->withToken(\$token)->postJson('/api/auth/logout');
        
        \$response->assertStatus(200);
        \$this->assertCount(0, \$user->tokens);
    }
}
PHP);

file_put_contents($testsDir.'/MeTest.php', <<<PHP
<?php
namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MeTest extends TestCase
{
    use RefreshDatabase;

    public function test_unauthenticated_request_is_rejected()
    {
        \$response = \$this->getJson('/api/auth/me');
        \$response->assertStatus(401);
    }

    public function test_authenticated_user_can_fetch_identity()
    {
        \$user = User::factory()->create();
        \$token = \$user->createToken('test')->plainTextToken;

        \$response = \$this->withToken(\$token)->getJson('/api/auth/me');
        \$response->assertStatus(200)
                 ->assertJsonPath('user.id', \$user->id);
    }
}
PHP);

file_put_contents($testsDir.'/SessionBootstrapTest.php', <<<PHP
<?php
namespace Tests\Feature\Auth;

use App\Models\User;
use App\Models\Business;
use App\Models\Branch;
use App\Models\Role;
use App\Models\Permission;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SessionBootstrapTest extends TestCase
{
    use RefreshDatabase;

    public function test_bootstrap_returns_trusted_context()
    {
        \$business = Business::factory()->create();
        \$branch = Branch::factory()->create(['business_id' => \$business->id]);
        
        \$user = User::factory()->create(['default_branch_id' => \$branch->id]);
        \$user->businesses()->attach(\$business->id);
        \$user->branches()->attach(\$branch->id);

        \$role = Role::create([
            'business_id' => \$business->id,
            'name' => 'Manager',
            'description' => 'Manager Role'
        ]);
        
        \$permission = Permission::create(['name' => 'sales.create', 'description' => 'Create Sales']);
        \$role->permissions()->attach(\$permission->id);
        \$user->roles()->attach(\$role->id);

        \$token = \$user->createToken('test')->plainTextToken;

        \$response = \$this->withToken(\$token)->getJson('/api/session/bootstrap');

        \$response->assertStatus(200)
                 ->assertJsonPath('user.id', \$user->id)
                 ->assertJsonPath('active_business.id', \$business->id)
                 ->assertJsonPath('active_branch.id', \$branch->id)
                 ->assertJsonFragment(['Manager'])
                 ->assertJsonFragment(['sales.create']);
    }
}
PHP);

file_put_contents($testsDir.'/TenantSecurityTest.php', <<<PHP
<?php
namespace Tests\Feature\Auth;

use App\Models\User;
use App\Models\Business;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TenantSecurityTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_cannot_bootstrap_unauthorized_business()
    {
        \$businessA = Business::factory()->create();
        \$userA = User::factory()->create();
        \$userA->businesses()->attach(\$businessA->id);

        \$businessB = Business::factory()->create();

        \$token = \$userA->createToken('test')->plainTextToken;

        \$response = \$this->withToken(\$token)->getJson('/api/session/bootstrap?business_id=' . \$businessB->id);

        \$response->assertStatus(403)
                 ->assertJsonFragment(['message' => 'Unauthorized access to requested business.']);
    }
}
PHP);

file_put_contents($testsDir.'/DeviceBindingTest.php', <<<PHP
<?php
namespace Tests\Feature\Auth;

use App\Models\User;
use App\Models\Business;
use App\Models\Device;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DeviceBindingTest extends TestCase
{
    use RefreshDatabase;

    public function test_device_can_be_registered()
    {
        \$business = Business::factory()->create();
        \$user = User::factory()->create();
        \$user->businesses()->attach(\$business->id);

        \$token = \$user->createToken('test')->plainTextToken;

        \$response = \$this->withToken(\$token)->postJson('/api/devices/register', [
            'business_id' => \$business->id,
            'device_uuid' => 'D-12345',
            'device_name' => 'POS-1',
            'platform' => 'Android'
        ]);

        \$response->assertStatus(200)
                 ->assertJsonPath('device.device_uuid', 'D-12345');
        
        \$this->assertDatabaseHas('devices', [
            'device_uuid' => 'D-12345',
            'business_id' => \$business->id
        ]);
    }

    public function test_device_registration_idempotency()
    {
        \$business = Business::factory()->create();
        \$user = User::factory()->create();
        \$user->businesses()->attach(\$business->id);

        \$device = Device::factory()->create([
            'business_id' => \$business->id,
            'device_uuid' => 'D-12345'
        ]);

        \$token = \$user->createToken('test')->plainTextToken;

        \$response = \$this->withToken(\$token)->postJson('/api/devices/register', [
            'business_id' => \$business->id,
            'device_uuid' => 'D-12345',
            'device_name' => 'Updated POS',
            'platform' => 'Android'
        ]);

        \$response->assertStatus(200);
        
        // Assert it updated, didn't create a new one
        \$this->assertDatabaseCount('devices', 1);
        \$this->assertEquals('Updated POS', \$device->fresh()->device_name);
    }

    public function test_revoked_device_is_rejected()
    {
        \$business = Business::factory()->create();
        \$user = User::factory()->create();
        \$user->businesses()->attach(\$business->id);

        \$device = Device::factory()->create([
            'business_id' => \$business->id,
            'device_uuid' => 'D-12345',
            'revoked_at' => now()
        ]);

        \$token = \$user->createToken('test')->plainTextToken;

        \$response = \$this->withToken(\$token)->postJson('/api/devices/register', [
            'business_id' => \$business->id,
            'device_uuid' => 'D-12345'
        ]);

        \$response->assertStatus(422)
                 ->assertJsonFragment(['This device is revoked and cannot be registered again.']);
    }
}
PHP);

echo "Test files generated.\n";
