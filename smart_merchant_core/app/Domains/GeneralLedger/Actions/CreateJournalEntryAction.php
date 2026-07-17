<?php

namespace App\Domains\GeneralLedger\Actions;

use App\Domains\Finance\Models\JournalEntry;
use App\Domains\GeneralLedger\Repositories\Contracts\JournalEntryRepositoryInterface;
use Illuminate\Support\Facades\DB;
use Exception;

class CreateJournalEntryAction
{
    private JournalEntryRepositoryInterface $repository;

    public function __construct(JournalEntryRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(array $data): JournalEntry
    {
        try {
            return DB::transaction(function () use ($data) {
                $lines = $data['lines'] ?? [];
                unset($data['lines']);
                
                $data['status'] = 'Draft';
                $entry = $this->repository->create($data);
                
                if (!empty($lines)) {
                    $this->repository->syncLines($entry->id, $lines);
                }
                
                return $this->repository->loadAggregate($entry->id);
            });
        } catch (Exception $e) {
            throw $e;
        }
    }
}
