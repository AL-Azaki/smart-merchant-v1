<?php

namespace Tests\Feature\Platform;

use App\Models\Account;
use App\Models\Business;
use App\Models\Product;
use App\Models\User;
use App\Services\Storefront\StorefrontSettingsService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class StorefrontSettingsApiTest extends TestCase
{
    use RefreshDatabase;

    protected Account $account;

    protected User $user;

    protected Business $business;

    protected function setUp(): void
    {
        parent::setUp();

        $this->account = Account::factory()->create();
        $this->user = User::factory()->create([
            'account_id' => $this->account->id,
        ]);
        $this->business = Business::factory()->create([
            'account_id' => $this->account->id,
            'business_name' => 'متجر الأمل التجاري',
            'primary_phone' => '+967771234567',
            'status' => 'Active',
            'storefront_active' => false,
            'storefront_slug' => null,
            'storefront_display_name' => null,
            'storefront_phone' => null,
            'storefront_whatsapp' => null,
        ]);

        config(['storefront.url' => 'http://localhost:3000']);
    }

    /**
     * 1. Unauthenticated user cannot read settings.
     */
    public function test_01_unauthenticated_user_cannot_read_settings(): void
    {
        $response = $this->getJson('/api/platform/storefront/settings');
        $response->assertStatus(401);
    }

    /**
     * 2. Unauthenticated user cannot update settings.
     */
    public function test_02_unauthenticated_user_cannot_update_settings(): void
    {
        $response = $this->putJson('/api/platform/storefront/settings', [
            'storefront_active' => false,
        ]);
        $response->assertStatus(401);
    }

    /**
     * 3. Authenticated merchant reads own settings only.
     */
    public function test_03_authenticated_merchant_reads_own_settings_only(): void
    {
        $this->business->update([
            'storefront_slug' => 'al-amal-store',
            'storefront_display_name' => 'الأمل شوب',
            'storefront_whatsapp' => '+967770000000',
            'storefront_phone' => '+967710000000',
            'storefront_address_text' => 'شارع الزبيري، صنعاء',
            'storefront_lat' => 15.3500000,
            'storefront_lng' => 44.2000000,
            'storefront_active' => true,
            'storefront_theme_settings' => ['primary_color' => '#10B981'],
        ]);

        Sanctum::actingAs($this->user);

        $response = $this->getJson('/api/platform/storefront/settings');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'storefront_active' => true,
                    'storefront_display_name' => 'الأمل شوب',
                    'effective_display_name' => 'الأمل شوب',
                    'storefront_slug' => 'al-amal-store',
                    'store_url' => 'http://localhost:3000/store/al-amal-store',
                    'storefront_whatsapp' => '+967770000000',
                    'storefront_phone' => '+967710000000',
                    'effective_phone' => '+967710000000',
                    'storefront_address_text' => 'شارع الزبيري، صنعاء',
                    'storefront_lat' => 15.35,
                    'storefront_lng' => 44.2,
                    'storefront_theme_settings' => [
                        'primary_color' => '#10B981',
                    ],
                ],
            ]);
    }

    /**
     * 4. GET settings falls back to business_name when storefront_display_name is empty.
     */
    public function test_04_get_settings_falls_back_to_business_name_when_display_name_is_empty(): void
    {
        Sanctum::actingAs($this->user);

        $response = $this->getJson('/api/platform/storefront/settings');

        $response->assertStatus(200)
            ->assertJsonPath('data.storefront_display_name', null)
            ->assertJsonPath('data.effective_display_name', 'متجر الأمل التجاري');

        // Confirm DB column was NOT overwritten
        $this->assertNull($this->business->fresh()->storefront_display_name);
    }

    /**
     * 5. GET settings falls back to primary_phone when storefront_phone is empty.
     */
    public function test_05_get_settings_falls_back_to_primary_phone_when_storefront_phone_is_empty(): void
    {
        Sanctum::actingAs($this->user);

        $response = $this->getJson('/api/platform/storefront/settings');

        $response->assertStatus(200)
            ->assertJsonPath('data.storefront_phone', null)
            ->assertJsonPath('data.effective_phone', '+967771234567');

        // Confirm DB column was NOT overwritten
        $this->assertNull($this->business->fresh()->storefront_phone);
    }

    /**
     * 6. GET settings returns store_url = null when slug is empty.
     */
    public function test_06_get_settings_returns_store_url_null_when_slug_is_null(): void
    {
        Sanctum::actingAs($this->user);

        $response = $this->getJson('/api/platform/storefront/settings');

        $response->assertStatus(200)
            ->assertJsonPath('data.storefront_slug', null)
            ->assertJsonPath('data.store_url', null);
    }

    /**
     * 7. PUT saves draft settings when storefront is inactive.
     */
    public function test_07_put_saves_draft_settings_when_storefront_inactive(): void
    {
        Sanctum::actingAs($this->user);

        $payload = [
            'storefront_active' => false,
            'storefront_display_name' => 'مسودة متجر تجريبي',
            'storefront_slug' => null,
            'storefront_whatsapp' => '770000000',
        ];

        $response = $this->putJson('/api/platform/storefront/settings', $payload);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'storefront_active' => false,
                    'storefront_display_name' => 'مسودة متجر تجريبي',
                    'storefront_slug' => null,
                    'store_url' => null,
                    'storefront_whatsapp' => '770000000',
                ],
            ]);

        $this->assertDatabaseHas('businesses', [
            'id' => $this->business->id,
            'storefront_active' => false,
            'storefront_display_name' => 'مسودة متجر تجريبي',
        ]);
    }

    /**
     * 8. PUT activates storefront when requirements are fully met.
     */
    public function test_08_put_activates_storefront_when_requirements_are_fully_met(): void
    {
        Sanctum::actingAs($this->user);

        $payload = [
            'storefront_active' => true,
            'storefront_slug' => 'alamal-market',
            'storefront_display_name' => 'متجر الأمل الحديث',
            'storefront_whatsapp' => '+967770000000',
            'storefront_phone' => '+967710000000',
            'storefront_address_text' => 'صنعاء، التحرير',
            'storefront_lat' => 15.3540000,
            'storefront_lng' => 44.2050000,
            'storefront_theme_settings' => [
                'primary_color' => '#3B82F6',
            ],
        ];

        $response = $this->putJson('/api/platform/storefront/settings', $payload);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'storefront_active' => true,
                    'storefront_slug' => 'alamal-market',
                    'store_url' => 'http://localhost:3000/store/alamal-market',
                    'storefront_display_name' => 'متجر الأمل الحديث',
                    'storefront_whatsapp' => '+967770000000',
                ],
            ]);

        $this->assertDatabaseHas('businesses', [
            'id' => $this->business->id,
            'storefront_active' => true,
            'storefront_slug' => 'alamal-market',
        ]);
    }

    /**
     * 9. Cannot activate storefront without slug.
     */
    public function test_09_cannot_activate_storefront_without_slug(): void
    {
        Sanctum::actingAs($this->user);

        $response = $this->putJson('/api/platform/storefront/settings', [
            'storefront_active' => true,
            'storefront_slug' => null,
            'storefront_display_name' => 'متجر بدون رابط',
            'storefront_phone' => '770000000',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['storefront_slug']);

        $this->assertFalse((bool) $this->business->fresh()->storefront_active);
    }

    /**
     * 10. Cannot activate storefront without contact channel.
     */
    public function test_10_cannot_activate_storefront_without_contact_channel(): void
    {
        // Business has no primary_phone
        $this->business->update([
            'primary_phone' => null,
            'storefront_phone' => null,
            'storefront_whatsapp' => null,
        ]);

        Sanctum::actingAs($this->user);

        $response = $this->putJson('/api/platform/storefront/settings', [
            'storefront_active' => true,
            'storefront_slug' => 'no-contact-store',
            'storefront_display_name' => 'متجر بدون تواصل',
            'storefront_phone' => null,
            'storefront_whatsapp' => null,
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['storefront_whatsapp']);

        $this->assertFalse((bool) $this->business->fresh()->storefront_active);
    }

    /**
     * 11. Rejects invalid slug syntax.
     */
    public function test_11_rejects_invalid_slug_syntax(): void
    {
        Sanctum::actingAs($this->user);

        // Arabic characters
        $resArabic = $this->putJson('/api/platform/storefront/settings', [
            'storefront_active' => false,
            'storefront_slug' => 'متجر-عربي',
        ]);
        $resArabic->assertStatus(422)->assertJsonValidationErrors(['storefront_slug']);

        // Too short (< 3 characters)
        $resShort = $this->putJson('/api/platform/storefront/settings', [
            'storefront_active' => false,
            'storefront_slug' => 'ab',
        ]);
        $resShort->assertStatus(422)->assertJsonValidationErrors(['storefront_slug']);

        // Too long (> 60 characters)
        $resLong = $this->putJson('/api/platform/storefront/settings', [
            'storefront_active' => false,
            'storefront_slug' => str_repeat('a', 65),
        ]);
        $resLong->assertStatus(422)->assertJsonValidationErrors(['storefront_slug']);

        // Disallowed special symbols
        $resSpecial = $this->putJson('/api/platform/storefront/settings', [
            'storefront_active' => false,
            'storefront_slug' => 'shop_name@123',
        ]);
        $resSpecial->assertStatus(422)->assertJsonValidationErrors(['storefront_slug']);
    }

    /**
     * 12. Normalizes slug uppercase, spaces, leading/trailing hyphens and repeated hyphens.
     */
    public function test_12_normalizes_slug_lowercase_and_trims_and_hyphenates(): void
    {
        Sanctum::actingAs($this->user);

        $response = $this->putJson('/api/platform/storefront/settings', [
            'storefront_active' => false,
            'storefront_slug' => '  --My   Awesome---Store--  ',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.storefront_slug', 'my-awesome-store');

        $this->assertDatabaseHas('businesses', [
            'id' => $this->business->id,
            'storefront_slug' => 'my-awesome-store',
        ]);
    }

    /**
     * 13. Rejects reserved slugs in PUT.
     */
    public function test_13_rejects_reserved_slug_in_put(): void
    {
        Sanctum::actingAs($this->user);

        foreach (['admin', 'api', 'platform', 'store', 'checkout'] as $reserved) {
            $response = $this->putJson('/api/platform/storefront/settings', [
                'storefront_active' => false,
                'storefront_slug' => $reserved,
            ]);

            $response->assertStatus(422)
                ->assertJsonValidationErrors(['storefront_slug']);
        }
    }

    /**
     * 14. Rejects slug already taken by another business.
     */
    public function test_14_rejects_slug_already_taken_by_another_business(): void
    {
        Business::factory()->create([
            'storefront_slug' => 'taken-slug',
            'status' => 'Active',
        ]);

        Sanctum::actingAs($this->user);

        $response = $this->putJson('/api/platform/storefront/settings', [
            'storefront_active' => false,
            'storefront_slug' => 'taken-slug',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['storefront_slug']);
    }

    /**
     * 15. Allows business to keep its own slug on update.
     */
    public function test_15_allows_business_to_keep_its_own_slug_on_update(): void
    {
        $this->business->update([
            'storefront_slug' => 'my-unique-slug',
        ]);

        Sanctum::actingAs($this->user);

        $response = $this->putJson('/api/platform/storefront/settings', [
            'storefront_active' => false,
            'storefront_slug' => 'my-unique-slug',
            'storefront_display_name' => 'تحديث الاسم فقط',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.storefront_slug', 'my-unique-slug')
            ->assertJsonPath('data.storefront_display_name', 'تحديث الاسم فقط');
    }

    /**
     * 16. Slug availability returns true for available slug.
     */
    public function test_16_slug_availability_returns_true_for_available_slug(): void
    {
        Sanctum::actingAs($this->user);

        $response = $this->getJson('/api/platform/storefront/slug-availability?slug=totally-fresh-slug');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'slug' => 'totally-fresh-slug',
                    'available' => true,
                    'store_url' => 'http://localhost:3000/store/totally-fresh-slug',
                ],
            ]);
    }

    /**
     * 17. Slug availability returns false for taken slug.
     */
    public function test_17_slug_availability_returns_false_for_taken_slug(): void
    {
        Business::factory()->create([
            'storefront_slug' => 'occupied-store',
            'status' => 'Active',
        ]);

        Sanctum::actingAs($this->user);

        $response = $this->getJson('/api/platform/storefront/slug-availability?slug=occupied-store');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'slug' => 'occupied-store',
                    'available' => false,
                    'store_url' => null,
                ],
            ]);
    }

    /**
     * 18. Slug availability ignores current business's own slug.
     */
    public function test_18_slug_availability_ignores_current_business_own_slug(): void
    {
        $this->business->update(['storefront_slug' => 'my-own-slug']);

        Sanctum::actingAs($this->user);

        $response = $this->getJson('/api/platform/storefront/slug-availability?slug=my-own-slug');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'slug' => 'my-own-slug',
                    'available' => true,
                    'store_url' => 'http://localhost:3000/store/my-own-slug',
                ],
            ]);
    }

    /**
     * 19. Slug availability returns false for reserved slug.
     */
    public function test_19_slug_availability_returns_false_for_reserved_slug(): void
    {
        Sanctum::actingAs($this->user);

        $response = $this->getJson('/api/platform/storefront/slug-availability?slug=admin');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'slug' => 'admin',
                    'available' => false,
                    'store_url' => null,
                ],
            ]);
    }

    /**
     * 20. Slug availability returns 422 for invalid syntax.
     */
    public function test_20_slug_availability_returns_422_for_invalid_syntax(): void
    {
        Sanctum::actingAs($this->user);

        $response = $this->getJson('/api/platform/storefront/slug-availability?slug=INVALID_CHARS@!');
        $response->assertStatus(422)
            ->assertJsonValidationErrors(['slug']);
    }

    /**
     * 21. Tenant A cannot modify Tenant B settings.
     */
    public function test_21_tenant_a_cannot_modify_tenant_b_settings(): void
    {
        $accountB = Account::factory()->create();
        $businessB = Business::factory()->create([
            'account_id' => $accountB->id,
            'business_name' => 'منشأة باء المستقلة',
            'storefront_slug' => 'tenant-b-store',
        ]);

        Sanctum::actingAs($this->user);

        // Attempt to pass business_id of tenant B in header or body
        $response = $this->withHeaders([
            'X-Business-ID' => $businessB->id,
        ])->putJson('/api/platform/storefront/settings', [
            'storefront_active' => false,
            'storefront_display_name' => 'محاولة اختراق منشأة أخرى',
        ]);

        $response->assertStatus(403);

        // Ensure Business B remains completely unmodified
        $this->assertEquals('منشأة باء المستقلة', $businessB->fresh()->business_name);
        $this->assertNull($businessB->fresh()->storefront_display_name);
    }

    /**
     * 22. Lat and Lng out of bounds are rejected.
     */
    public function test_22_lat_and_lng_out_of_bounds_are_rejected(): void
    {
        Sanctum::actingAs($this->user);

        $resLat = $this->putJson('/api/platform/storefront/settings', [
            'storefront_active' => false,
            'storefront_lat' => 95.0, // max is 90
        ]);
        $resLat->assertStatus(422)->assertJsonValidationErrors(['storefront_lat']);

        $resLng = $this->putJson('/api/platform/storefront/settings', [
            'storefront_active' => false,
            'storefront_lng' => -190.0, // min is -180
        ]);
        $resLng->assertStatus(422)->assertJsonValidationErrors(['storefront_lng']);
    }

    /**
     * 23. Invalid theme settings are rejected.
     */
    public function test_23_invalid_theme_settings_are_rejected(): void
    {
        Sanctum::actingAs($this->user);

        $response = $this->putJson('/api/platform/storefront/settings', [
            'storefront_active' => false,
            'storefront_theme_settings' => [
                'primary_color' => 'blue', // not a valid hex color
            ],
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['storefront_theme_settings.primary_color']);
    }

    /**
     * 24. PUT request is idempotent without duplicate records.
     */
    public function test_24_put_request_is_idempotent_without_duplicate_records(): void
    {
        Sanctum::actingAs($this->user);

        $payload = [
            'storefront_active' => false,
            'storefront_slug' => 'idempotent-shop',
            'storefront_display_name' => 'متجر التكرار',
            'storefront_whatsapp' => '+967770000111',
        ];

        $res1 = $this->putJson('/api/platform/storefront/settings', $payload);
        $res1->assertStatus(200);

        $res2 = $this->putJson('/api/platform/storefront/settings', $payload);
        $res2->assertStatus(200);

        $this->assertEquals(1, Business::where('storefront_slug', 'idempotent-shop')->count());
        $this->assertEquals('متجر التكرار', $this->business->fresh()->storefront_display_name);
    }

    /**
     * 25. Deactivating storefront does not alter sync or product data.
     */
    public function test_25_deactivating_storefront_does_not_affect_products_or_sync(): void
    {
        $product = Product::factory()->create([
            'business_id' => $this->business->id,
            'product_name' => 'منتج تجريبي في المتجر',
            'show_in_store' => true,
        ]);

        $initialRevision = $this->business->revision;

        Sanctum::actingAs($this->user);

        $response = $this->putJson('/api/platform/storefront/settings', [
            'storefront_active' => false,
            'storefront_slug' => 'active-to-inactive',
        ]);

        $response->assertStatus(200);

        // Product show_in_store remains untouched
        $this->assertTrue((bool) $product->fresh()->show_in_store);
        $this->assertEquals($initialRevision, $this->business->fresh()->revision);
    }

    /**
     * 26. Response does not leak internal columns or business_id.
     */
    public function test_26_response_does_not_leak_internal_columns_or_business_id(): void
    {
        Sanctum::actingAs($this->user);

        $response = $this->getJson('/api/platform/storefront/settings');

        $response->assertStatus(200);
        $data = $response->json('data');

        $this->assertArrayNotHasKey('id', $data);
        $this->assertArrayNotHasKey('business_id', $data);
        $this->assertArrayNotHasKey('account_id', $data);
        $this->assertArrayNotHasKey('created_at', $data);
        $this->assertArrayNotHasKey('updated_at', $data);
        $this->assertArrayNotHasKey('deleted_at', $data);
        $this->assertArrayNotHasKey('revision', $data);
        $this->assertArrayNotHasKey('status', $data);
    }

    /**
     * 27. buildStoreUrl trims trailing slashes from STOREFRONT_URL config.
     */
    public function test_27_store_url_trims_trailing_slash_from_configured_storefront_url(): void
    {
        config(['storefront.url' => 'https://market.example.com///']);

        $url = StorefrontSettingsService::buildStoreUrl('my-store');
        $this->assertEquals('https://market.example.com/store/my-store', $url);

        // When slug is null or empty, buildStoreUrl returns null
        $this->assertNull(StorefrontSettingsService::buildStoreUrl(null));
        $this->assertNull(StorefrontSettingsService::buildStoreUrl('   '));
    }

    /**
     * 28. Saving settings without custom display_name or phone preserves null fallback in DB.
     */
    public function test_28_saving_without_custom_display_name_preserves_null_fallback_in_db(): void
    {
        Sanctum::actingAs($this->user);

        $payload = [
            'storefront_active' => false,
            'storefront_slug' => 'draft-fallback-test',
        ];

        $response = $this->putJson('/api/platform/storefront/settings', $payload);
        $response->assertStatus(200);

        // Assert DB columns remain null (dynamic fallback preserved)
        $fresh = $this->business->fresh();
        $this->assertNull($fresh->storefront_display_name);
        $this->assertNull($fresh->storefront_phone);

        // Assert API resource provides effective computed values
        $response->assertJsonPath('data.storefront_display_name', null);
        $response->assertJsonPath('data.effective_display_name', 'متجر الأمل التجاري');
        $response->assertJsonPath('data.storefront_phone', null);
        $response->assertJsonPath('data.effective_phone', '+967771234567');
    }

    /**
     * 29. Deliberate override persists in DB and does not mutate business original name or phone.
     */
    public function test_29_deliberate_override_persists_in_db_and_does_not_mutate_business_name(): void
    {
        Sanctum::actingAs($this->user);

        $payload = [
            'storefront_active' => false,
            'storefront_slug' => 'override-shop',
            'storefront_display_name' => 'الاسم المخصص للمتجر',
            'storefront_phone' => '+967711999888',
        ];

        $response = $this->putJson('/api/platform/storefront/settings', $payload);
        $response->assertStatus(200);

        $fresh = $this->business->fresh();
        $this->assertEquals('الاسم المخصص للمتجر', $fresh->storefront_display_name);
        $this->assertEquals('+967711999888', $fresh->storefront_phone);

        // Core business attributes MUST remain untouched
        $this->assertEquals('متجر الأمل التجاري', $fresh->business_name);
        $this->assertEquals('+967771234567', $fresh->primary_phone);
    }

    /**
     * 30. Clearing storefront override restores null in DB and dynamic fallback.
     */
    public function test_30_clearing_override_restores_null_and_fallback(): void
    {
        $this->business->update([
            'storefront_display_name' => 'اسم قديم سيتم حذفه',
            'storefront_phone' => '+967711999888',
            'storefront_slug' => 'clear-override-shop',
        ]);

        Sanctum::actingAs($this->user);

        // Send empty strings to reset
        $payload = [
            'storefront_active' => false,
            'storefront_slug' => 'clear-override-shop',
            'storefront_display_name' => '',
            'storefront_phone' => '',
        ];

        $response = $this->putJson('/api/platform/storefront/settings', $payload);
        $response->assertStatus(200);

        $fresh = $this->business->fresh();
        $this->assertNull($fresh->storefront_display_name);
        $this->assertNull($fresh->storefront_phone);
        $this->assertEquals('متجر الأمل التجاري', $fresh->business_name);

        $response->assertJsonPath('data.storefront_display_name', null);
        $response->assertJsonPath('data.effective_display_name', 'متجر الأمل التجاري');
    }

    /**
     * 31. Multi-tenant isolation: User A cannot access or mutate settings of Business B.
     */
    public function test_31_tenant_isolation_user_a_cannot_access_or_mutate_business_b(): void
    {
        $accountB = Account::factory()->create();
        User::factory()->create(['account_id' => $accountB->id]);
        $businessB = Business::factory()->create([
            'account_id' => $accountB->id,
            'business_name' => 'شركة المنافس',
            'storefront_slug' => 'competitor-store',
            'storefront_display_name' => 'متجر المنافس الأصلي',
        ]);

        Sanctum::actingAs($this->user);

        // User A attempts to tamper using X-Business-ID header pointing to Business B
        $response = $this->withHeader('X-Business-ID', (string) $businessB->id)
            ->putJson('/api/platform/storefront/settings', [
                'storefront_active' => false,
                'storefront_display_name' => 'محاولة اختراق محظورة',
            ]);

        $response->assertStatus(403);

        // Confirm Business B is unchanged
        $this->assertEquals('متجر المنافس الأصلي', $businessB->fresh()->storefront_display_name);
    }

    /**
     * 32. Slug conflict / race condition during PUT returns 422 cleanly without 500.
     */
    public function test_32_slug_conflict_race_condition_returns_422_without_500(): void
    {
        $otherAccount = Account::factory()->create();
        Business::factory()->create([
            'account_id' => $otherAccount->id,
            'storefront_slug' => 'race-conflict-slug',
            'status' => 'Active',
        ]);

        Sanctum::actingAs($this->user);

        $payload = [
            'storefront_active' => false,
            'storefront_slug' => 'race-conflict-slug',
        ];

        $response = $this->putJson('/api/platform/storefront/settings', $payload);
        $response->assertStatus(422)
            ->assertJsonValidationErrors(['storefront_slug']);
    }

    /**
     * 33. Client-provided store_url field in PUT payload is strictly ignored.
     */
    public function test_33_put_ignores_client_provided_store_url_field(): void
    {
        Sanctum::actingAs($this->user);

        $payload = [
            'storefront_active' => false,
            'storefront_slug' => 'valid-shop-slug',
            'store_url' => 'https://malicious-phishing-site.com/fake-store',
        ];

        $response = $this->putJson('/api/platform/storefront/settings', $payload);
        $response->assertStatus(200);

        // store_url in response must point to configured STOREFRONT_URL, never the injected client URL
        $this->assertEquals('http://localhost:3000/store/valid-shop-slug', $response->json('data.store_url'));
    }
}
