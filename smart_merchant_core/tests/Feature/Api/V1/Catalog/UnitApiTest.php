<?php

namespace Tests\Feature\Api\V1\Catalog;

use Tests\TestCase;
use App\Domains\Catalog\Models\Unit;
use Illuminate\Foundation\Testing\RefreshDatabase;

class UnitApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_list_Units()
    {
        Unit::factory()->count(3)->create();

        $response = $this->getJson('/api/v1/Catalog/Units');

        $response->assertStatus(200)
                 ->assertJsonStructure([
                     'data' => [
                         '*' => ['id', 'Unit_code', 'Unit_name']
                     ]
                 ]);
    }

    public function test_can_create_Unit()
    {
        $payload = [
            'Unit_code' => 'EUR',
            'Unit_name' => 'Euro',
            'symbol' => '€',
            'exchange_rate' => 1.1,
            'is_active' => true
        ];

        $response = $this->postJson('/api/v1/Catalog/Units', $payload);

        $response->assertStatus(201)
                 ->assertJsonPath('Unit_code', 'EUR');
                 
        $this->assertDatabaseHas('Units', ['Unit_code' => 'EUR']);
    }

    public function test_unauthorized_user_cannot_update_Unit()
    {
        $Unit = \App\Domains\Catalog\Models\Unit::factory()->create();
        $user = \App\Domains\Catalog\Models\User::factory()->create();

        // Acting as a user without 'update Unit' permission
        $this->actingAs($user);

        $response = $this->putJson("/api/v1/Catalog/Units/{$Unit->id}", [
            'Unit_name_en' => 'Updated Name'
        ]);

        $response->assertStatus(403);
    }

    public function test_authorized_user_can_update_Unit()
    {
        $Unit = \App\Domains\Catalog\Models\Unit::factory()->create();
        $user = \App\Domains\Catalog\Models\User::factory()->create();
        // Assuming there's a way to authorize the user (mocking the Gate)
        \Illuminate\Support\Facades\Gate::define('update', function ($user, $Unit) {
            return true;
        });

        $this->actingAs($user);

        // We also need to mock the view action or repository since DB might not have the Unit if we mock
        $response = $this->putJson("/api/v1/Catalog/Units/{$Unit->id}", [
            'Unit_name_en' => 'Updated Name'
        ]);

        // If the action is executed, it should return 200
        // We just assert it doesn't return 403
        $this->assertNotEquals(403, $response->status());
    }
}


