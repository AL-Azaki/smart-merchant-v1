<?php

namespace App\Domains\GeneralLedger\Actions;

use App\Domains\Finance\Models\JournalEntry;
use App\Domains\GeneralLedger\Repositories\Contracts\JournalEntryRepositoryInterface;
use Illuminate\Support\Facades\DB;
use Exception;
use RuntimeException;

class UpdateJournalEntryAction
{
    private JournalEntryRepositoryInterface $repository;

    public function __construct(JournalEntryRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $id, array $data): JournalEntry
    {
        try {
            return DB::transaction(function () use ($id, $data) {
                $entry = $this->repository->findById($id);
                if (!$entry || $entry->status !== 'Draft') {
                    throw new RuntimeException("Only Draft journal entries can be updated.");
                }

                $lines = $data['lines'] ?? [];
                unset($data['lines']);
                
                $entry = $this->repository->update($id, $data);
                
                if (isset($lines)) {
                    $this->repository->syncLines($entry->id, $lines);
                }
                
                return $this->repository->loadAggregate($entry->id);
            });
        } catch (Exception $e) {
            throw $e;
        }
    }
}
