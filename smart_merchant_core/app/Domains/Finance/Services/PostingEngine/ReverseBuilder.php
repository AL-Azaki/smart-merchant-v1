<?php

namespace App\Domains\Finance\Services\PostingEngine;

use App\Domains\Finance\DTOs\PostingEngine\ReverseRequestDTO;
use App\Domains\Finance\Exceptions\PostingEngineException;
use App\Domains\Finance\Models\JournalEntry;
use App\Domains\Finance\Repositories\Contracts\FiscalPeriodRepositoryInterface;
use App\Domains\Finance\Repositories\Contracts\JournalEntryLineRepositoryInterface;
use App\Domains\Finance\Repositories\Contracts\JournalEntryRepositoryInterface;
use Carbon\Carbon;

class ReverseBuilder
{
    private JournalEntryRepositoryInterface $journalRepo;
    private JournalEntryLineRepositoryInterface $lineRepo;
    private FiscalPeriodRepositoryInterface $fiscalPeriodRepo;

    public function __construct(
        JournalEntryRepositoryInterface $journalRepo,
        JournalEntryLineRepositoryInterface $lineRepo,
        FiscalPeriodRepositoryInterface $fiscalPeriodRepo
    ) {
        $this->journalRepo = $journalRepo;
        $this->lineRepo = $lineRepo;
        $this->fiscalPeriodRepo = $fiscalPeriodRepo;
    }

    public function build(ReverseRequestDTO $request): JournalEntry
    {
        $original = $this->journalRepo->findById($request->originalJournalId);
        
        if (!$original) {
            throw new \InvalidArgumentException('Original journal not found.');
        }

        if ($original->status === 'Draft') {
            throw PostingEngineException::reverseDraftNotAllowed();
        }

        if ($original->status === 'Reversed') {
            throw PostingEngineException::reverseAlreadyReversed();
        }

        // Validate posting date for reverse journal
        $postingDate = Carbon::parse($request->postingDate)->startOfDay();
        
        // Find open fiscal period for the posting date
        // Note: For simplicity we could use a query to find the period covering this date.
        // Assuming findOverlapping exists or we can fetch the period. 
        // The architecture contract says "تاريخ ترحيل القيد العكسي (إلزامي، يجب أن يقع في فترة مالية مفتوحة)"
        $period = $this->fiscalPeriodRepo->findOverlapping($original->fiscal_year_id, $postingDate->toDateString(), $postingDate->toDateString());
        
        if (!$period || $period->status !== 'Open') {
            throw PostingEngineException::invalidFiscalPeriod();
        }

        $journalNumber = $this->journalRepo->getNextJournalNumber($original->business_id);

        $reverseData = [
            'business_id' => $original->business_id,
            'fiscal_year_id' => $period->fiscal_year_id,
            'fiscal_period_id' => $period->id,
            'journal_number' => $journalNumber,
            'document_date' => $original->document_date,
            'posting_date' => $request->postingDate,
            'journal_type' => 'Reverse',
            'document_type' => $original->document_type,
            'document_id' => $original->document_id,
            'document_number' => $original->document_number,
            'original_journal_id' => $original->id,
            'currency_id' => $original->currency_id,
            'exchange_rate' => $original->exchange_rate,
            'description' => $request->description ?? 'Reversal of ' . $original->journal_number,
            'status' => 'Posted',
            'created_by' => $request->reversedBy,
            'posted_by' => $request->reversedBy,
            'posted_at' => Carbon::now(),
        ];

        $reverseJournal = $this->journalRepo->create($reverseData);

        $linesData = [];
        $lineNumber = 1;
        // Assuming relationship 'lines' is eager loaded or lazy loaded
        foreach ($original->lines as $originalLine) {
            $linesData[] = [
                'business_id' => $originalLine->business_id,
                'journal_entry_id' => $reverseJournal->id,
                'line_number' => $lineNumber++,
                'chart_of_account_id' => $originalLine->chart_of_account_id,
                'description' => $originalLine->description,
                'currency_id' => $originalLine->currency_id,
                'exchange_rate' => $originalLine->exchange_rate,
                'type' => $originalLine->type === 'Debit' ? 'Credit' : 'Debit', // Reverse logic
                'foreign_amount' => $originalLine->foreign_amount,
                'base_amount' => $originalLine->base_amount,
            ];
        }

        $this->lineRepo->createMany($linesData);

        // Update original journal
        $this->journalRepo->update($original, [
            'status' => 'Reversed',
            'reversed_by' => $request->reversedBy,
            'reversed_at' => Carbon::now(),
        ]);

        return $reverseJournal;
    }
}
