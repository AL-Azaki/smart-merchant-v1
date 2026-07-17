<?php

namespace App\Domains\GeneralLedger\Actions;

use App\Domains\Finance\Models\JournalEntry;
use App\Domains\GeneralLedger\Repositories\Contracts\JournalEntryRepositoryInterface;
use Illuminate\Support\Facades\DB;
use Exception;
use RuntimeException;
use Illuminate\Support\Str;

class ReverseJournalEntryAction
{
    private JournalEntryRepositoryInterface $repository;

    public function __construct(JournalEntryRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $id, string $userId, array $reversalData = []): JournalEntry
    {
        try {
            return DB::transaction(function () use ($id, $userId, $reversalData) {
                $originalEntry = $this->repository->loadAggregate($id);
                if (!$originalEntry || $originalEntry->status !== 'Posted') {
                    throw new RuntimeException("Only Posted journal entries can be reversed.");
                }

                // Create Reversal Entry
                $reversalEntryData = [
                    'business_id' => $originalEntry->business_id,
                    'fiscal_year_id' => $originalEntry->fiscal_year_id,
                    'fiscal_period_id' => $originalEntry->fiscal_period_id,
                    'journal_number' => $reversalData['journal_number'] ?? 'REV-' . $originalEntry->journal_number,
                    'document_date' => $reversalData['document_date'] ?? now()->toDateString(),
                    'posting_date' => $reversalData['posting_date'] ?? now()->toDateString(),
                    'journal_type' => 'Reverse',
                    'document_type' => $originalEntry->document_type,
                    'document_id' => $originalEntry->document_id,
                    'document_number' => $originalEntry->document_number,
                    'original_journal_id' => $originalEntry->id,
                    'currency_id' => $originalEntry->currency_id,
                    'exchange_rate' => $originalEntry->exchange_rate,
                    'description' => "Reversal of {$originalEntry->journal_number}",
                    'status' => 'Posted',
                    'created_by' => $userId,
                    'posted_by' => $userId,
                    'posted_at' => now(),
                ];

                $reversalLines = $originalEntry->lines->map(function ($line) {
                    return [
                        'business_id' => $line->business_id,
                        'line_number' => $line->line_number,
                        'chart_of_account_id' => $line->chart_of_account_id,
                        'description' => 'Reversal: ' . $line->description,
                        'currency_id' => $line->currency_id,
                        'exchange_rate' => $line->exchange_rate,
                        'type' => $line->type === 'Debit' ? 'Credit' : 'Debit',
                        'foreign_amount' => $line->foreign_amount,
                        'base_amount' => $line->base_amount,
                        'document_type' => $line->document_type,
                        'document_id' => $line->document_id,
                    ];
                })->toArray();

                $reversalEntry = $this->repository->create($reversalEntryData);
                $this->repository->syncLines($reversalEntry->id, $reversalLines);

                // Update original entry
                $this->repository->update($originalEntry->id, [
                    'status' => 'Reversed',
                    'reversed_by' => $userId,
                    'reversed_at' => now(),
                ]);

                return $this->repository->loadAggregate($reversalEntry->id);
            });
        } catch (Exception $e) {
            throw $e;
        }
    }
}
