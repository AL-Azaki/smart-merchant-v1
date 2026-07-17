<?php

namespace App\Domains\GeneralLedger\Actions;

use App\Domains\Finance\Models\JournalEntry;
use App\Domains\GeneralLedger\Repositories\Contracts\JournalEntryRepositoryInterface;

class LoadJournalEntryAggregateAction
{
    private JournalEntryRepositoryInterface $repository;

    public function __construct(JournalEntryRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $id): ?JournalEntry
    {
        return $this->repository->loadAggregate($id);
    }
}
