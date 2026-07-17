<?php

namespace App\Domains\GeneralLedger\Actions;

use App\Domains\Finance\Models\JournalEntry;
use App\Domains\GeneralLedger\Repositories\Contracts\JournalEntryRepositoryInterface;
use Illuminate\Support\Facades\DB;
use Exception;
use RuntimeException;
use App\Domains\GeneralLedger\Events\JournalEntryPosted;

class PostJournalEntryAction
{
    private JournalEntryRepositoryInterface $repository;

    public function __construct(JournalEntryRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $id, string $userId): JournalEntry
    {
        try {
            return DB::transaction(function () use ($id, $userId) {
                $entry = $this->repository->loadAggregate($id);
                if (!$entry || $entry->status !== 'Draft') {
                    throw new RuntimeException("Only Draft journal entries can be posted.");
                }

                // Balance validation
                $totalDebits = $entry->lines->where('type', 'Debit')->sum('base_amount');
                $totalCredits = $entry->lines->where('type', 'Credit')->sum('base_amount');

                if (bccomp((string)$totalDebits, (string)$totalCredits, 2) !== 0) {
                    throw new RuntimeException("Journal Entry must be balanced before posting.");
                }

                // Additional logic to check if Fiscal Period is Open could be placed here or in a domain service

                $updatedEntry = $this->repository->update($id, [
                    'status' => 'Posted',
                    'posted_by' => $userId,
                    'posted_at' => now(),
                ]);

                event(new JournalEntryPosted($updatedEntry, $userId));

                return $updatedEntry;
            });
        } catch (Exception $e) {
            throw $e;
        }
    }
}
