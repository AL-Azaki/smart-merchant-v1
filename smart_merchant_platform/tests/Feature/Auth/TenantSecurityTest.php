<?php

namespace Tests\Feature\Auth;

use App\Models\Branch;
use App\Models\Business;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TenantSecurityTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_cannot_bootstrap_unauthorized_business()
    {
        $businessA = Business::factory()->create();
        $branchA = Branch::factory()->create(['business_id' => $businessA->id]);
        $userA = User::factory()->create(['default_branch_id' => null]);
        $userA->branches()->attach($branchA->id);

        $businessB = Business::factory()->create();

        $token = $userA->createToken('test')->plainTextToken;

        $response = $this->withToken($token)->getJson('/api/session/bootstrap?business_id='.$businessB->id);

        $response->assertStatus(403)
            ->assertJsonFragment(['message' => 'Unauthorized access to requested business.']);
    }
}
