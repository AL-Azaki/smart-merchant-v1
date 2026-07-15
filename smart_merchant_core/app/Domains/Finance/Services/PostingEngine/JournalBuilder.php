<?php

namespace App\Domains\Finance\Services\PostingEngine;

use App\Domains\Finance\DTOs\PostingEngine\PostingRequestDTO;
use App\Domains\Finance\Models\JournalEntry;
use App\Domains\Finance\Repositories\Contracts\FiscalPeriodRepositoryInterface;
use App\Domains\Finance\Repositories\Contracts\JournalEntryLineRepositoryInterface;
use App\Domains\Finance\Repositories\Contracts\JournalEntryRepositoryInterface;
use Carbon\Carbon;

class JournalBuilder
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

    public function build(PostingRequestDTO $request): JournalEntry
    {
        $journalNumber = $this->journalRepo->getNextJournalNumber($request->businessId);
        $period = $this->fiscalPeriodRepo->findById($request->fiscalPeriodId);

        $journalData = [
            'business_id' => $request->businessId,
            'fiscal_year_id' => $period->fiscal_year_id,
            'fiscal_period_id' => $request->fiscalPeriodId,
            'journal_number' => $journalNumber,
            'document_date' => $request->documentDate,
            'posting_date' => $request->postingDate,
            'journal_type' => $request->journalType,
            'document_type' => $request->documentType,
            'document_id' => $request->documentId,
            'document_number' => $request->documentNumber,
            'currency_id' => $request->currencyId,
            'exchange_rate' => $request->exchangeRate,
            'description' => $request->description,
            'status' => 'Posted',
            'created_by' => $request->createdBy,
            'posted_by' => $request->createdBy,
            'posted_at' => Carbon::now(),
        ];

        $journal = $this->journalRepo->create($journalData);

        $linesData = [];
        $lineNumber = 1;
        foreach ($request->lines as $lineDTO) {
            $linesData[] = [
                'business_id' => $request->businessId,
                'journal_entry_id' => $journal->id,
                'line_number' => $lineNumber++,
                'chart_of_account_id' => $lineDTO->chartOfAccountId,
                'description' => $lineDTO->description ?? $request->description,
                'currency_id' => $request->currencyId,
                'exchange_rate' => $request->exchangeRate,
                'type' => $lineDTO->type,
                'foreign_amount' => $lineDTO->foreignAmount,
                'base_amount' => $lineDTO->baseAmount,
            ];
        }

        $this->lineRepo->createMany($linesData);

        return $journal;
    }
}
