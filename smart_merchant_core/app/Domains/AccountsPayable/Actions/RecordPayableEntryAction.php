<?php

namespace App\Domains\AccountsPayable\Actions;

use App\Domains\AccountsPayable\Repositories\Contracts\SupplierPayableRepositoryInterface;
use Illuminate\Support\Facades\DB;
use Exception;
use RuntimeException;

class RecordPayableEntryAction
{
    private SupplierPayableRepositoryInterface $repository;

    public function __construct(SupplierPayableRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $payableId, array $entryData): void
    {
        try {
            DB::transaction(function () use ($payableId, $entryData) {
                $payable = $this->repository->findById($payableId);
                if (! $payable) {
                    throw new RuntimeException("SupplierPayable not found.");
                }

                $this->repository->addEntry($payableId, $entryData);

                // Recalculate balance: Credit increases payable (we owe more), Debit decreases (we paid)
                $balanceChange = $entryData['amount'];
                if ($entryData['direction'] === 'Debit') {
                    $balanceChange = -$balanceChange;
                }

                $newBalance = $payable->current_balance + $balanceChange;
                if ($newBalance < 0) {
                    throw new RuntimeException("Supplier payable balance cannot become negative.");
                }

                $updateData = ['current_balance' => $newBalance];

                // State machine
                if ($newBalance == 0) {
                    $updateData['status'] = 'Fully Paid';
                } elseif ($newBalance > 0 && $payable->status === 'Fully Paid') {
                    $updateData['status'] = 'Open';
                }

                $this->repository->update($payableId, $updateData);
            });
        } catch (Exception $e) {
            throw $e;
        }
    }
}
