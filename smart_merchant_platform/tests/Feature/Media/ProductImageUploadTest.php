<?php

namespace Tests\Feature\Media;

use App\Models\Business;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProductImageUploadTest extends TestCase
{
    use RefreshDatabase;

    protected $user;
    protected $business;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::factory()->create();
        $this->business = Business::factory()->create();
    }

    public function test_unauthenticated_user_cannot_upload_product_image()
    {
        Storage::fake('public');

        $file = UploadedFile::fake()->image('test_product.jpg', 600, 600);

        $response = $this->postJson('/api/media/product-image', [
            'image' => $file,
        ]);

        $response->assertStatus(401);
    }

    public function test_authenticated_user_can_upload_valid_product_image()
    {
        Storage::fake('public');
        Sanctum::actingAs($this->user);

        $file = UploadedFile::fake()->image('iphone_15.webp', 800, 800);

        $response = $this->postJson('/api/media/product-image', [
            'image' => $file,
        ]);

        $response->assertStatus(201);
        $response->assertJsonStructure([
            'success',
            'url',
            'path',
            'filename',
        ]);
        $this->assertTrue($response->json('success'));

        $path = $response->json('path');
        Storage::disk('public')->assertExists($path);
    }

    public function test_invalid_file_rejected()
    {
        Storage::fake('public');
        Sanctum::actingAs($this->user);

        $file = UploadedFile::fake()->create('document.pdf', 100);

        $response = $this->postJson('/api/media/product-image', [
            'image' => $file,
        ]);

        $response->assertStatus(422);
        $response->assertJsonValidationErrors(['image']);
    }
}
