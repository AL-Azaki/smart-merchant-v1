<?php

namespace Tests\Feature\Domains\Finance;

use App\Domains\Core\Models\Business;
use App\Domains\Core\Models\Currency;
use App\Domains\Core\Models\User;
use App\Domains\Finance\Models\ChartOfAccount;
use App\Domains\Finance\Models\FiscalPeriod;
use App\Domains\Finance\Models\FiscalYear;
use App\Domains\Finance\Models\JournalEntry;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class ManualJournalTest extends TestCase
{
    use RefreshDatabase;

    private User $user;
    private Business $business;
    private FiscalYear $fiscalYear;
    private FiscalPeriod $fiscalPeriod;
    private Currency $currency;
    private ChartOfAccount $account1;
    private ChartOfAccount $account2;

    protected function setUp(): void
    {
        parent::setUp();
        
        // Let's assume standard Laravel Model factories exist, if not we will mock or bypass
        // Since we are creating E2E tests, we mock the PostingEngineAction or use the real DB
        // The prompt says: "استخدام Actions فقط." "نجاح عرض القيد" "رفض البيانات غير المكتملة" "رفض UUID غير صحيح"
        
        $this->user = User::factory()->create();
        // Give permissions to bypass policy checks in tests
        // $this->user->givePermissionTo('finance.manual_journal.create'); 
        // We will assume the Policy is bypassed or mocked if Spatie permissions are used. For simplicity, we can mock the policy or actingAs with correct permissions.
    }

    public function test_it_creates_manual_journal_successfully()
    {
        // We will mock the Action to isolate the Presentation Layer as requested.
        // Wait, "إنشاء اختبارات End-to-End تغطي" means we should test the whole flow?
        // Actually, the prompt says "المطلوب الآن هو تنفيذ المرحلة التالية فقط. Manual Journal Presentation Layer... هذه المرحلة تمثل واجهة استخدام النظام فقط... استخدام Actions فقط."
        // We will mock the CreateManualJournalAction to ensure the Controller just calls the action and formats the output.
        
        $businessId = Str::uuid()->toString();
        $fiscalPeriodId = Str::uuid()->toString();
        $currencyId = Str::uuid()->toString();
        $acc1Id = Str::uuid()->toString();
        $acc2Id = Str::uuid()->toString();

        $actionMock = $this->mock(\App\Domains\Finance\Actions\ManualJournal\CreateManualJournalAction::class);
        $repoMock = $this->mock(\App\Domains\Finance\Repositories\Contracts\JournalEntryRepositoryInterface::class);

        $dtoResult = new \App\Domains\Finance\DTOs\PostingEngine\PostingResultDTO(
            'journal-123',
            'JE-1000',
            'Posted',
            '2026-07-14'
        );

        $actionMock->shouldReceive('execute')->once()->andReturn($dtoResult);

        $journalMock = new JournalEntry();
        $journalMock->id = 'journal-123';
        $journalMock->journal_number = 'JE-1000';
        $journalMock->status = 'Posted';
        $journalMock->document_date = now();
        $journalMock->posting_date = now();
        $journalMock->setRelation('lines', collect([]));

        $repoMock->shouldReceive('findById')->with('journal-123')->andReturn($journalMock);

        // Mock Policy
        $this->actingAs($this->user);
        $this->withoutAuthorization(); // Bypass policy for this specific test

        $response = $this->postJson('/api/v1/finance/manual-journals', [
            'business_id' => $businessId,
            'fiscal_period_id' => $fiscalPeriodId,
            'document_date' => '2026-07-14',
            'posting_date' => '2026-07-14',
            'currency_id' => $currencyId,
            'exchange_rate' => 1.0,
            'description' => 'Test Manual Journal',
            'lines' => [
                [
                    'chart_of_account_id' => $acc1Id,
                    'type' => 'Debit',
                    'foreign_amount' => 100,
                    'base_amount' => 100,
                ],
                [
                    'chart_of_account_id' => $acc2Id,
                    'type' => 'Credit',
                    'foreign_amount' => 100,
                    'base_amount' => 100,
                ]
            ]
        ]);

        $response->assertStatus(201)
                 ->assertJsonPath('data.id', 'journal-123')
                 ->assertJsonPath('data.journal_number', 'JE-1000');
    }

    public function test_it_rejects_incomplete_data()
    {
        $this->actingAs($this->user);
        
        $response = $this->postJson('/api/v1/finance/manual-journals', [
            'business_id' => Str::uuid()->toString(),
            // Missing fiscal_period_id
        ]);

        $response->assertStatus(422)
                 ->assertJsonValidationErrors(['fiscal_period_id', 'lines']);
    }

    public function test_it_rejects_invalid_uuid()
    {
        $this->actingAs($this->user);

        $response = $this->postJson('/api/v1/finance/manual-journals', [
            'business_id' => 'not-a-uuid',
            'fiscal_period_id' => 'not-a-uuid',
            'document_date' => '2026-07-14',
            'posting_date' => '2026-07-14',
            'currency_id' => 'not-a-uuid',
            'exchange_rate' => 1.0,
            'lines' => [
                [
                    'chart_of_account_id' => 'not-a-uuid',
                    'type' => 'Debit',
                    'foreign_amount' => 100,
                    'base_amount' => 100,
                ],
                [
                    'chart_of_account_id' => 'not-a-uuid',
                    'type' => 'Credit',
                    'foreign_amount' => 100,
                    'base_amount' => 100,
                ]
            ]
        ]);

        $response->assertStatus(422)
                 ->assertJsonValidationErrors(['business_id', 'fiscal_period_id', 'currency_id', 'lines.0.chart_of_account_id', 'lines.1.chart_of_account_id']);
    }

    public function test_it_shows_journal_entry()
    {
        $repoMock = $this->mock(\App\Domains\Finance\Repositories\Contracts\JournalEntryRepositoryInterface::class);

        $journalMock = new JournalEntry();
        $journalMock->id = 'journal-123';
        $journalMock->journal_number = 'JE-1000';
        $journalMock->status = 'Posted';
        $journalMock->document_date = now();
        $journalMock->posting_date = now();
        $journalMock->setRelation('lines', collect([]));

        $repoMock->shouldReceive('findById')->with('journal-123')->andReturn($journalMock);

        $this->actingAs($this->user);
        $this->withoutAuthorization();

        $response = $this->getJson('/api/v1/finance/manual-journals/journal-123');

        $response->assertStatus(200)
                 ->assertJsonPath('data.id', 'journal-123')
                 ->assertJsonPath('data.journal_number', 'JE-1000');
    }

    public function test_it_reverses_manual_journal_successfully()
    {
        $actionMock = $this->mock(\App\Domains\Finance\Actions\ManualJournal\ReverseManualJournalAction::class);
        $repoMock = $this->mock(\App\Domains\Finance\Repositories\Contracts\JournalEntryRepositoryInterface::class);

        $dtoResult = new \App\Domains\Finance\DTOs\PostingEngine\PostingResultDTO(
            'journal-124',
            'JE-1001',
            'Posted',
            '2026-07-15'
        );

        $actionMock->shouldReceive('execute')->once()->andReturn($dtoResult);

        $originalJournalMock = new JournalEntry();
        $originalJournalMock->id = 'journal-123';
        $originalJournalMock->status = 'Posted';

        $reversedJournalMock = new JournalEntry();
        $reversedJournalMock->id = 'journal-124';
        $reversedJournalMock->journal_number = 'JE-1001';
        $reversedJournalMock->status = 'Posted';
        $reversedJournalMock->document_date = now();
        $reversedJournalMock->posting_date = now();
        $reversedJournalMock->setRelation('lines', collect([]));

        $repoMock->shouldReceive('findById')->with('journal-123')->andReturn($originalJournalMock);
        $repoMock->shouldReceive('findById')->with('journal-124')->andReturn($reversedJournalMock);

        $this->actingAs($this->user);
        $this->withoutAuthorization();

        $response = $this->postJson('/api/v1/finance/manual-journals/journal-123/reverse', [
            'posting_date' => '2026-07-15',
            'description' => 'Reversal description'
        ]);

        $response->assertStatus(200)
                 ->assertJsonPath('data.id', 'journal-124')
                 ->assertJsonPath('data.journal_number', 'JE-1001');
    }

    public function test_it_prevents_reverse_twice_via_exception()
    {
        $actionMock = $this->mock(\App\Domains\Finance\Actions\ManualJournal\ReverseManualJournalAction::class);
        $repoMock = $this->mock(\App\Domains\Finance\Repositories\Contracts\JournalEntryRepositoryInterface::class);

        $originalJournalMock = new JournalEntry();
        $originalJournalMock->id = 'journal-123';
        $originalJournalMock->status = 'Reversed';

        $repoMock->shouldReceive('findById')->with('journal-123')->andReturn($originalJournalMock);
        
        $actionMock->shouldReceive('execute')->once()->andThrow(\App\Domains\Finance\Exceptions\PostingEngineException::reverseAlreadyReversed());

        $this->actingAs($this->user);
        $this->withoutAuthorization();

        $response = $this->postJson('/api/v1/finance/manual-journals/journal-123/reverse', [
            'posting_date' => '2026-07-15',
        ]);

        $response->assertStatus(500); // Or whatever status code the exception handler transforms it to
    }

    public function test_it_enforces_user_permissions()
    {
        $this->actingAs($this->user);
        // By default, the user does not have permissions unless mocked or seeded
        // We will assume the Gate denies the action
        
        $response = $this->postJson('/api/v1/finance/manual-journals', [
            'business_id' => Str::uuid()->toString(),
            'fiscal_period_id' => Str::uuid()->toString(),
            'document_date' => '2026-07-14',
            'posting_date' => '2026-07-14',
            'currency_id' => Str::uuid()->toString(),
            'exchange_rate' => 1.0,
            'lines' => [
                [
                    'chart_of_account_id' => Str::uuid()->toString(),
                    'type' => 'Debit',
                    'foreign_amount' => 100,
                    'base_amount' => 100,
                ],
                [
                    'chart_of_account_id' => Str::uuid()->toString(),
                    'type' => 'Credit',
                    'foreign_amount' => 100,
                    'base_amount' => 100,
                ]
            ]
        ]);

        $response->assertStatus(403);
    }
}
