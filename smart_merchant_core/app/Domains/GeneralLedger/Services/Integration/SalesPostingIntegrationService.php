<?php

namespace App\Domains\GeneralLedger\Services\Integration;

use App\Domains\GeneralLedger\Actions\CreateJournalEntryAction;
use App\Domains\GeneralLedger\Actions\PostJournalEntryAction;
use App\Domains\Finance\DTOs\PostingRequestDTO;
use Illuminate\Support\Str;

class SalesPostingIntegrationService
{
    private CreateJournalEntryAction $createAction;
    private PostJournalEntryAction $postAction;

    public function __construct(
        CreateJournalEntryAction $createAction,
        PostJournalEntryAction $postAction
    ) {
        $this->createAction = $createAction;
        $this->postAction = $postAction;
    }

    public function handleSalesPostingRequest(PostingRequestDTO $request, string $userId): void
    {
        // Translate PostingRequestDTO to JournalEntry Creation Array
        $data = [
            'business_id' => $request->businessId,
            'fiscal_year_id' => Str::uuid()->toString(), // Resolved via Finance Domain
            'fiscal_period_id' => Str::uuid()->toString(), // Resolved via Finance Domain
            'journal_number' => 'SLS-' . strtoupper(Str::random(6)),
            'document_date' => $request->date,
            'journal_type' => 'SalesInvoice',
            'document_type' => $request->documentType,
            'document_id' => $request->documentId,
            'currency_id' => $request->currencyId,
            'exchange_rate' => 1.0,
            'description' => $request->description,
            'created_by' => $userId,
            'lines' => [],
        ];

        $lineNumber = 1;
        foreach ($request->lines as $line) {
            $data['lines'][] = [
                'business_id' => $request->businessId,
                'line_number' => $lineNumber++,
                'chart_of_account_id' => $line->accountId,
                'description' => $request->description,
                'currency_id' => $request->currencyId,
                'exchange_rate' => 1.0,
                'type' => $line->debitAmount > 0 ? 'Debit' : 'Credit',
                'foreign_amount' => $line->debitAmount > 0 ? $line->debitAmount : $line->creditAmount,
                'base_amount' => $line->debitAmount > 0 ? $line->debitAmount : $line->creditAmount,
                'document_type' => $request->documentType,
                'document_id' => $request->documentId,
            ];
        }

        $entry = $this->createAction->execute($data);
        $this->postAction->execute($entry->id, $userId);
    }
}
