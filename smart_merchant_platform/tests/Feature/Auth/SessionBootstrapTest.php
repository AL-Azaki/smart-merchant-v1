<?php

namespace Tests\Feature\Auth;

use App\Models\Branch;
use App\Models\Business;
use App\Models\Permission;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SessionBootstrapTest extends TestCase
{
    use RefreshDatabase;

    public function test_bootstrap_returns_trusted_context()
    {
        $business = Business::factory()->create();
        $branch = Branch::factory()->create(['business_id' => $business->id]);

        $user = User::factory()->create(['default_branch_id' => null]);
        $user->branches()->attach($branch->id);
        $user->update(['default_branch_id' => $branch->id]);

        $role = Role::create([
            'business_id' => $business->id,
            'role_name' => 'Manager',
            'description' => 'Manager Role',
        ]);

        $permission = Permission::create([
            'module' => 'sales',
            'permission_code' => 'sales.create',
            'permission_name' => 'Create Sales',
        ]);
        $role->permissions()->attach($permission->id);
        $user->roles()->attach($role->id);

        $token = $user->createToken('test')->plainTextToken;

        $response = $this->withToken($token)->getJson('/api/session/bootstrap');

        $response->assertStatus(200)
            ->assertJsonPath('user.id', $user->id)
            ->assertJsonPath('active_business.id', $business->id)
            ->assertJsonPath('active_branch.id', $branch->id)
            ->assertJsonFragment(['Manager'])
            ->assertJsonFragment(['sales.create']);
    }
}
