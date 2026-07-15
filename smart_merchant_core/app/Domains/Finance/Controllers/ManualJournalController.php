<?php

namespace App\Domains\Finance\Controllers;

use App\Http\Controllers\Controller;
use App\Domains\Finance\Actions\ManualJournal\CreateManualJournalAction;
use App\Domains\Finance\Actions\ManualJournal\ReverseManualJournalAction;
use App\Domains\Finance\DTOs\ManualJournal\CreateManualJournalDTO;
use App\Domains\Finance\DTOs\ManualJournal\CreateManualJournalLineDTO;
use App\Domains\Finance\DTOs\ManualJournal\ReverseManualJournalDTO;
use App\Domains\Finance\Models\JournalEntry;
use App\Domains\Finance\Repositories\Contracts\JournalEntryRepositoryInterface;
use App\Domains\Finance\Requests\ManualJournal\StoreManualJournalRequest;
use App\Domains\Finance\Requests\ManualJournal\ReverseManualJournalRequest;
use App\Domains\Finance\Resources\ManualJournalResource;
use Illuminate\Http\JsonResponse;

class ManualJournalController extends Controller
{
    private JournalEntryRepositoryInterface $repository;

    public function __construct(JournalEntryRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function store(StoreManualJournalRequest $request, CreateManualJournalAction $action): JsonResponse
    {
        $this->authorize('create', JournalEntry::class);

        $lines = [];
        foreach ($request->validated('lines') as $line) {
            $lines[] = new CreateManualJournalLineDTO(
                $line['chart_of_account_id'],
                $line['type'],
                $line['foreign_amount'],
                $line['base_amount'],
                $line['description'] ?? null
            );
        }

        $dto = new CreateManualJournalDTO(
            $request->validated('business_id'),
            $request->validated('fiscal_period_id'),
            $request->validated('document_date'),
            $request->validated('posting_date'),
            $request->validated('currency_id'),
            $request->validated('exchange_rate'),
            $request->validated('description'),
            $request->user()->id,
            $lines
        );

        $result = $action->execute($dto);

        $journal = $this->repository->findById($result->journalEntryId);
        $journal->load('lines');

        return response()->json([
            'data' => new ManualJournalResource($journal)
        ], 201);
    }

    public function show(string $id): JsonResponse
    {
        $journal = $this->repository->findById($id);
        
        if (!$journal) {
            abort(404);
        }

        $this->authorize('view', $journal);

        $journal->load('lines');

        return response()->json([
            'data' => new ManualJournalResource($journal)
        ]);
    }

    public function reverse(ReverseManualJournalRequest $request, string $id, ReverseManualJournalAction $action): JsonResponse
    {
        $journal = $this->repository->findById($id);
        
        if (!$journal) {
            abort(404);
        }

        $this->authorize('reverse', $journal);

        $dto = new ReverseManualJournalDTO(
            $journal->id,
            $request->validated('posting_date'),
            $request->user()->id,
            $request->validated('description')
        );

        $result = $action->execute($dto);

        $reversedJournal = $this->repository->findById($result->journalEntryId);
        $reversedJournal->load('lines');

        return response()->json([
            'data' => new ManualJournalResource($reversedJournal)
        ]);
    }
}
