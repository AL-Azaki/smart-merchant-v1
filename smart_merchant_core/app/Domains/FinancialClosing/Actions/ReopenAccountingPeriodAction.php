<?php

namespace App\Domains\FinancialClosing\Actions;

use App\Domains\FinancialClosing\Models\AccountingPeriod;
use App\Domains\FinancialClosing\Repositories\Contracts\AccountingPeriodRepositoryInterface;
use Illuminate\Support\Facades\DB;
use Exception;
use RuntimeException;
use App\Domains\FinancialClosing\Events\AccountingPeriodReopened;

class ReopenAccountingPeriodAction
{
    private AccountingPeriodRepositoryInterface $repository;

    public function __construct(AccountingPeriodRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $id, string $userId, string $reason): AccountingPeriod
    {
        try {
            return DB::transaction(function () use ($id, $userId, $reason) {
                $period = $this->repository->findById($id);
                if (!$period) {
                    throw new RuntimeException("Accounting period not found.");
                }
                if ($period->status !== 'Closed') {
                    throw new RuntimeException("Only Closed periods can be reopened.");
                }
                if (empty($reason)) {
                    throw new RuntimeException("A reason is required to reopen a closed period.");
                }

                $updatedPeriod = $this->repository->update($id, [
                    'status' => 'Reopened',
                    'reopened_by' => $userId,
                    'reopened_at' => now(),
                    'reopen_reason' => $reason,
                    'updated_by' => $userId,
                ]);

                event(new AccountingPeriodReopened($updatedPeriod, $userId, $reason));

                return $updatedPeriod;
            });
        } catch (Exception $e) {
            throw $e;
        }
    }
}
