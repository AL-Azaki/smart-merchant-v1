<?php

namespace App\Domains\AccountsReceivable\Actions;

use App\Domains\AccountsReceivable\Repositories\Contracts\CustomerReceivableRepositoryInterface;
use Illuminate\Support\Facades\DB;
use Exception;

class RecordReceivableEntryAction
{
    private CustomerReceivableRepositoryInterface $repository;

    public function __construct(CustomerReceivableRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $receivableId, array $entryData): void
    {
        try {
            DB::transaction(function () use ($receivableId, $entryData) {
                // Determine balance impact based on direction
                // (Note: Outstanding balance update is delegated strictly, 
                // but we modify the aggregate here safely within transaction)
                
                $receivable = $this->repository->findById($receivableId);
                if (! $receivable) {
                    throw new \RuntimeException("CustomerReceivable not found.");
                }
                
                $this->repository->addEntry($receivableId, $entryData);
                
                // Recalculate balance logic
                $balanceChange = $entryData['amount'];
                if ($entryData['direction'] === 'Credit') {
                    $balanceChange = -$balanceChange;
                }
                
                $newBalance = $receivable->current_balance + $balanceChange;
                if ($newBalance < 0) {
                    throw new \RuntimeException("Customer receivable balance cannot become negative.");
                }
                
                $updateData = ['current_balance' => $newBalance];
                
                // State machine logic
                if ($newBalance == 0) {
                    $updateData['status'] = 'Fully Paid';
                } elseif ($newBalance > 0 && $receivable->status === 'Fully Paid') {
                    $updateData['status'] = 'Open';
                }
                
                $this->repository->update($receivableId, $updateData);
            });
        } catch (Exception $e) {
            throw $e;
        }
    }
}
