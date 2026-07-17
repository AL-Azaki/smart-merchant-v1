<?php

namespace App\Domains\GeneralLedger\Actions;

use App\Domains\GeneralLedger\Repositories\Contracts\JournalEntryRepositoryInterface;
use Illuminate\Support\Collection;

class ListJournalEntriesAction
{
    private JournalEntryRepositoryInterface $repository;

    public function __construct(JournalEntryRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(array $filters = []): Collection
    {
        return $this->repository->list($filters);
    }
}
