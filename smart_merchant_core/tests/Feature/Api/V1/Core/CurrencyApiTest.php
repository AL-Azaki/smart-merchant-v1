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
}
