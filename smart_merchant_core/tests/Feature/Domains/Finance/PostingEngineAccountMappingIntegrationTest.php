<?php

namespace Tests\Feature\Domains\Finance;

use App\Domains\Core\Models\Business;
use App\Domains\Core\Models\Currency;
use App\Domains\Core\Models\User;
use App\Domains\Finance\Actions\AccountMapping\ResolveAccountMappingAction;
use App\Domains\Finance\Contracts\PostingEngineInterface;
use App\Domains\Finance\DTOs\PostingEngine\PostingLineDTO;
use App\Domains\Finance\DTOs\PostingEngine\PostingRequestDTO;
use App\Domains\Finance\Models\AccountMapping;
use App\Domains\Finance\Models\ChartOfAccount;
use App\Domains\Finance\Models\FiscalPeriod;
use App\Domains\Finance\Models\FiscalYear;
use App\Domains\Finance\Models\JournalEntry;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class PostingEngineAccountMappingIntegrationTest extends TestCase
{
    use RefreshDatabase;

    private ResolveAccountMappingAction $resolveAction;
    private PostingEngineInterface $postingEngine;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->resolveAction = app(ResolveAccountMappingAction::class);
        $this->postingEngine = app(PostingEngineInterface::class);
    }

    public function test_it_successfully_resolves_mapping_and_posts_journal_entry()
    {
        // 1. Setup Data
        // Assume factories exist. We will manually create required data to ensure test runs.
        // As this is a pure integration test without actual DB seeding here, we use DB facade to insert raw test data or mock if needed.
        // Wait, since we are using real integration, we should insert minimal required data.
        
        $businessId = \Illuminate\Support\Str::uuid()->toString();
        $currencyId = \Illuminate\Support\Str::uuid()->toString();
        
        DB::table('businesses')->insert(['id' => $businessId, 'name' => 'Test Business']);
        DB::table('currencies')->insert(['id' => $currencyId, 'code' => 'USD', 'name' => 'US Dollar', 'symbol' => '$', 'exchange_rate' => 1.0]);

        $fiscalYearId = \Illuminate\Support\Str::uuid()->toString();
        DB::table('fiscal_years')->insert([
            'id' => $fiscalYearId,
            'business_id' => $businessId,
            'name' => '2026',
            'start_date' => '2026-01-01',
            'end_date' => '2026-12-31',
            'status' => 'Open'
        ]);

        $fiscalPeriodId = \Illuminate\Support\Str::uuid()->toString();
        DB::table('fiscal_periods')->insert([
            'id' => $fiscalPeriodId,
            'business_id' => $businessId,
            'fiscal_year_id' => $fiscalYearId,
            'name' => 'July 2026',
            'start_date' => '2026-07-01',
            'end_date' => '2026-07-31',
            'status' => 'Open'
        ]);

        $salesAccountId = \Illuminate\Support\Str::uuid()->toString();
        DB::table('chart_of_accounts')->insert([
            'id' => $salesAccountId,
            'business_id' => $businessId,
            'account_code' => '4000',
            'name' => 'Sales Revenue',
            'type' => 'Revenue',
            'is_active' => true,
            'allow_posting' => true,
            'currency_id' => $currencyId
        ]);

        $cashAccountId = \Illuminate\Support\Str::uuid()->toString();
        DB::table('chart_of_accounts')->insert([
            'id' => $cashAccountId,
            'business_id' => $businessId,
            'account_code' => '1000',
            'name' => 'Cash',
            'type' => 'Asset',
            'is_active' => true,
            'allow_posting' => true,
            'currency_id' => $currencyId
        ]);

        // 2. Create Mappings
        DB::table('account_mappings')->insert([
            'id' => \Illuminate\Support\Str::uuid()->toString(),
            'business_id' => $businessId,
            'mapping_type' => 'SalesRevenue',
            'chart_of_account_id' => $salesAccountId
        ]);

        DB::table('account_mappings')->insert([
            'id' => \Illuminate\Support\Str::uuid()->toString(),
            'business_id' => $businessId,
            'mapping_type' => 'Cash',
            'chart_of_account_id' => $cashAccountId
        ]);

        // 3. The Orchestration (Simulating a caller e.g. SalesInvoicePostingAction)
        $result = DB::transaction(function () use ($businessId, $fiscalPeriodId, $currencyId) {
            
            // Resolve Accounts
            $salesAccount = $this->resolveAction->execute($businessId, 'SalesRevenue');
            $cashAccount = $this->resolveAction->execute($businessId, 'Cash');

            $this->assertNotNull($salesAccount);
            $this->assertNotNull($cashAccount);

            // Build DTO
            $lines = [
                new PostingLineDTO($cashAccount->id, 'Debit', 100, 100, 'Cash Received'),
                new PostingLineDTO($salesAccount->id, 'Credit', 100, 100, 'Sales Revenue')
            ];

            $requestDTO = new PostingRequestDTO(
                $businessId,
                $fiscalPeriodId,
                '2026-07-14',
                '2026-07-14',
                'SalesInvoice',
                'SalesInvoice',
                'inv-123',
                'INV-1000',
                $currencyId,
                1.0,
                'Invoice Posting Test',
                'system',
                $lines
            );

            // Post
            return $this->postingEngine->post($requestDTO);
        });

        // 4. Assertions
        $this->assertNotNull($result->journalEntryId);
        
        $journal = DB::table('journal_entries')->where('id', $result->journalEntryId)->first();
        $this->assertNotNull($journal);
        $this->assertEquals('SalesInvoice', $journal->document_type);

        $lines = DB::table('journal_entry_lines')->where('journal_entry_id', $journal->id)->get();
        $this->assertCount(2, $lines);
        
        $debitLine = $lines->where('type', 'Debit')->first();
        $creditLine = $lines->where('type', 'Credit')->first();

        $this->assertEquals($cashAccountId, $debitLine->chart_of_account_id);
        $this->assertEquals($salesAccountId, $creditLine->chart_of_account_id);
    }

    public function test_it_rolls_back_if_mapping_is_missing()
    {
        $businessId = \Illuminate\Support\Str::uuid()->toString();

        $initialJournalsCount = DB::table('journal_entries')->count();

        // Simulate Orchestrator
        try {
            DB::transaction(function () use ($businessId) {
                // This will throw exception because mapping doesn't exist
                $salesAccount = $this->resolveAction->execute($businessId, 'MissingMappingType');
                
                // Unreachable code
                $this->fail('Should not reach here');
            });
        } catch (\Exception $e) {
            $this->assertStringContainsString("Account Mapping not found for type: MissingMappingType", $e->getMessage());
        }

        // Verify Rollback
        $finalJournalsCount = DB::table('journal_entries')->count();
        $this->assertEquals($initialJournalsCount, $finalJournalsCount);
    }
}
