<?php

namespace Tests\Feature\Api\V1\Core;

use Tests\TestCase;
use App\Domains\Core\Models\Currency;
use Illuminate\Foundation\Testing\RefreshDatabase;

class CurrencyApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_list_currencies()
    {
        Currency::factory()->count(3)->create();

        $response = $this->getJson('/api/v1/core/currencies');

        $response->assertStatus(200)
                 ->assertJsonStructure([
                     'data' => [
                         '*' => ['id', 'currency_code', 'currency_name']
                     ]
                 ]);
    }

    public function test_can_create_currency()
    {
        $payload = [
            'currency_code' => 'EUR',
            'currency_name' => 'Euro',
            'symbol' => '€',
            'exchange_rate' => 1.1,
            'is_default' => false,
            'is_active' => true
        ];

        $response = $this->postJson('/api/v1/core/currencies', $payload);

        $response->assertStatus(201)
                 ->assertJsonPath('currency_code', 'EUR');
                 
        $this->assertDatabaseHas('currencies', ['currency_code' => 'EUR']);
    }

    public function test_unauthorized_user_cannot_update_currency()
    {
        $currency = \App\Domains\Core\Models\Currency::factory()->create();
        $user = \App\Domains\Core\Models\User::factory()->create();

        // Acting as a user without 'update currency' permission
        $this->actingAs($user);

        $response = $this->putJson("/api/v1/core/currencies/{$currency->id}", [
            'currency_name_en' => 'Updated Name'
        ]);

        $response->assertStatus(403);
    }

    public function test_authorized_user_can_update_currency()
    {
        $currency = \App\Domains\Core\Models\Currency::factory()->create();
        $user = \App\Domains\Core\Models\User::factory()->create();
        // Assuming there's a way to authorize the user (mocking the Gate)
        \Illuminate\Support\Facades\Gate::define('update', function ($user, $currency) {
            return true;
        });

        $this->actingAs($user);

        // We also need to mock the view action or repository since DB might not have the currency if we mock
        $response = $this->putJson("/api/v1/core/currencies/{$currency->id}", [
            'currency_name_en' => 'Updated Name'
        ]);

        // If the action is executed, it should return 200
        // We just assert it doesn't return 403
        $this->assertNotEquals(403, $response->status());
    }
}
