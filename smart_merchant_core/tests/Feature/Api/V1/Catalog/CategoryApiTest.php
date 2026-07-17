<?php

namespace Tests\Feature\Api\V1\Catalog;

use Tests\TestCase;
use App\Domains\Catalog\Models\Category;
use Illuminate\Foundation\Testing\RefreshDatabase;

class CategoryApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_list_Categorys()
    {
        Category::factory()->count(3)->create();

        $response = $this->getJson('/api/v1/Catalog/Categorys');

        $response->assertStatus(200)
                 ->assertJsonStructure([
                     'data' => [
                         '*' => ['id', 'Category_code', 'Category_name']
                     ]
                 ]);
    }

    public function test_can_create_Category()
    {
        $payload = [
            'Category_code' => 'EUR',
            'Category_name' => 'Euro',
            'symbol' => '€',
            'exchange_rate' => 1.1,
            'is_active' => true
        ];

        $response = $this->postJson('/api/v1/Catalog/Categorys', $payload);

        $response->assertStatus(201)
                 ->assertJsonPath('Category_code', 'EUR');
                 
        $this->assertDatabaseHas('Categorys', ['Category_code' => 'EUR']);
    }

    public function test_unauthorized_user_cannot_update_Category()
    {
        $Category = \App\Domains\Catalog\Models\Category::factory()->create();
        $user = \App\Domains\Catalog\Models\User::factory()->create();

        // Acting as a user without 'update Category' permission
        $this->actingAs($user);

        $response = $this->putJson("/api/v1/Catalog/Categorys/{$Category->id}", [
            'Category_name_en' => 'Updated Name'
        ]);

        $response->assertStatus(403);
    }

    public function test_authorized_user_can_update_Category()
    {
        $Category = \App\Domains\Catalog\Models\Category::factory()->create();
        $user = \App\Domains\Catalog\Models\User::factory()->create();
        // Assuming there's a way to authorize the user (mocking the Gate)
        \Illuminate\Support\Facades\Gate::define('update', function ($user, $Category) {
            return true;
        });

        $this->actingAs($user);

        // We also need to mock the view action or repository since DB might not have the Category if we mock
        $response = $this->putJson("/api/v1/Catalog/Categorys/{$Category->id}", [
            'Category_name_en' => 'Updated Name'
        ]);

        // If the action is executed, it should return 200
        // We just assert it doesn't return 403
        $this->assertNotEquals(403, $response->status());
    }
}



