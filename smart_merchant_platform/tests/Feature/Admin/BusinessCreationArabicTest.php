<?php

namespace Tests\Feature\Admin;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;
use Laravel\Sanctum\Sanctum;

class BusinessCreationArabicTest extends TestCase
{
    use RefreshDatabase;

    public function test_business_creation_accepts_arabic_text()
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $arabicName = 'مؤسسة Smart Merchant للتجارة';

        $response = $this->postJson('/api/admin/v1/businesses', [
            'business_name' => $arabicName,
            'business_type' => 'retail',
            'primary_phone' => '123456789',
            'primary_email' => 'test@example.com',
        ]);

        $response->assertStatus(201);
        
        $this->assertDatabaseHas('businesses', [
            'business_name' => $arabicName,
            'account_id' => $user->account_id,
        ]);
    }
}
