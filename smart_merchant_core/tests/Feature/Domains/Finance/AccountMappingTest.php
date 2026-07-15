<?php

namespace Tests\Feature\Domains\Finance;

use App\Domains\Core\Models\User;
use App\Domains\Finance\Models\AccountMapping;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class AccountMappingTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->user = User::factory()->create();
    }

    public function test_it_creates_account_mapping_successfully()
    {
        $businessId = Str::uuid()->toString();
        $chartOfAccountId = Str::uuid()->toString();

        $actionMock = $this->mock(\App\Domains\Finance\Actions\AccountMapping\CreateAccountMappingAction::class);
        
        $mappingMock = new AccountMapping();
        $mappingMock->id = Str::uuid()->toString();
        $mappingMock->business_id = $businessId;
        $mappingMock->mapping_type = 'SalesRevenue';
        $mappingMock->chart_of_account_id = $chartOfAccountId;
        
        $actionMock->shouldReceive('execute')->once()->andReturn($mappingMock);

        $this->actingAs($this->user);
        $this->withoutAuthorization();

        $response = $this->postJson('/api/v1/finance/account-mappings', [
            'business_id' => $businessId,
            'mapping_type' => 'SalesRevenue',
            'chart_of_account_id' => $chartOfAccountId,
        ]);

        $response->assertStatus(201)
                 ->assertJsonPath('data.mapping_type', 'SalesRevenue')
                 ->assertJsonPath('data.business_id', $businessId);
    }

    public function test_it_rejects_incomplete_data()
    {
        $this->actingAs($this->user);
        
        $response = $this->postJson('/api/v1/finance/account-mappings', [
            'business_id' => Str::uuid()->toString(),
            // Missing mapping_type and chart_of_account_id
        ]);

        $response->assertStatus(422)
                 ->assertJsonValidationErrors(['mapping_type', 'chart_of_account_id']);
    }

    public function test_it_updates_account_mapping_successfully()
    {
        $businessId = Str::uuid()->toString();
        $newChartOfAccountId = Str::uuid()->toString();

        $getActionMock = $this->mock(\App\Domains\Finance\Actions\AccountMapping\GetAccountMappingAction::class);
        $updateActionMock = $this->mock(\App\Domains\Finance\Actions\AccountMapping\UpdateAccountMappingAction::class);
        
        $mappingMock = new AccountMapping();
        $mappingMock->id = Str::uuid()->toString();
        $mappingMock->business_id = $businessId;
        $mappingMock->mapping_type = 'SalesRevenue';

        $updatedMock = clone $mappingMock;
        $updatedMock->chart_of_account_id = $newChartOfAccountId;

        $getActionMock->shouldReceive('execute')->with($businessId, 'SalesRevenue')->once()->andReturn($mappingMock);
        $updateActionMock->shouldReceive('execute')->once()->andReturn($updatedMock);

        $this->actingAs($this->user);
        $this->withoutAuthorization();

        $response = $this->putJson("/api/v1/finance/account-mappings/{$businessId}/SalesRevenue", [
            'chart_of_account_id' => $newChartOfAccountId,
        ]);

        $response->assertStatus(200)
                 ->assertJsonPath('data.chart_of_account_id', $newChartOfAccountId);
    }

    public function test_it_deletes_account_mapping_successfully()
    {
        $businessId = Str::uuid()->toString();

        $getActionMock = $this->mock(\App\Domains\Finance\Actions\AccountMapping\GetAccountMappingAction::class);
        $deleteActionMock = $this->mock(\App\Domains\Finance\Actions\AccountMapping\DeleteAccountMappingAction::class);
        
        $mappingMock = new AccountMapping();
        $mappingMock->id = Str::uuid()->toString();

        $getActionMock->shouldReceive('execute')->with($businessId, 'SalesRevenue')->once()->andReturn($mappingMock);
        $deleteActionMock->shouldReceive('execute')->once()->andReturn(true);

        $this->actingAs($this->user);
        $this->withoutAuthorization();

        $response = $this->deleteJson("/api/v1/finance/account-mappings/{$businessId}/SalesRevenue");

        $response->assertStatus(204);
    }

    public function test_it_shows_account_mapping()
    {
        $businessId = Str::uuid()->toString();

        $getActionMock = $this->mock(\App\Domains\Finance\Actions\AccountMapping\GetAccountMappingAction::class);
        
        $mappingMock = new AccountMapping();
        $mappingMock->id = Str::uuid()->toString();
        $mappingMock->mapping_type = 'SalesRevenue';

        $getActionMock->shouldReceive('execute')->with($businessId, 'SalesRevenue')->once()->andReturn($mappingMock);

        $this->actingAs($this->user);
        $this->withoutAuthorization();

        $response = $this->getJson("/api/v1/finance/account-mappings/{$businessId}/SalesRevenue");

        $response->assertStatus(200)
                 ->assertJsonPath('data.mapping_type', 'SalesRevenue');
    }

    public function test_it_lists_all_account_mappings_for_business()
    {
        $businessId = Str::uuid()->toString();

        $listActionMock = $this->mock(\App\Domains\Finance\Actions\AccountMapping\ListAccountMappingsAction::class);
        
        $mappingMock1 = new AccountMapping();
        $mappingMock1->mapping_type = 'SalesRevenue';
        
        $mappingMock2 = new AccountMapping();
        $mappingMock2->mapping_type = 'AccountsReceivable';

        $listActionMock->shouldReceive('execute')->with($businessId)->once()->andReturn(collect([$mappingMock1, $mappingMock2]));

        $this->actingAs($this->user);
        $this->withoutAuthorization();

        $response = $this->getJson("/api/v1/finance/account-mappings?business_id={$businessId}");

        $response->assertStatus(200)
                 ->assertJsonCount(2, 'data')
                 ->assertJsonPath('data.0.mapping_type', 'SalesRevenue')
                 ->assertJsonPath('data.1.mapping_type', 'AccountsReceivable');
    }

    public function test_it_prevents_duplicate_mapping_via_exception()
    {
        $businessId = Str::uuid()->toString();
        $chartOfAccountId = Str::uuid()->toString();

        $actionMock = $this->mock(\App\Domains\Finance\Actions\AccountMapping\CreateAccountMappingAction::class);
        
        $actionMock->shouldReceive('execute')->once()->andThrow(new \Exception("Mapping already exists for this type in this business."));

        $this->actingAs($this->user);
        $this->withoutAuthorization();

        $response = $this->postJson('/api/v1/finance/account-mappings', [
            'business_id' => $businessId,
            'mapping_type' => 'SalesRevenue',
            'chart_of_account_id' => $chartOfAccountId,
        ]);

        $response->assertStatus(500); // Handled as 500 or whatever custom exception handler outputs
    }

    public function test_it_enforces_user_permissions()
    {
        $this->actingAs($this->user);
        // Without mocked policy or assigned roles, it should deny access
        
        $response = $this->postJson('/api/v1/finance/account-mappings', [
            'business_id' => Str::uuid()->toString(),
            'mapping_type' => 'SalesRevenue',
            'chart_of_account_id' => Str::uuid()->toString(),
        ]);

        $response->assertStatus(403);
    }
}
