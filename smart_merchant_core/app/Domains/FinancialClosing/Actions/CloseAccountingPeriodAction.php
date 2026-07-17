<?php

namespace App\Domains\FinancialClosing\Actions;

use App\Domains\FinancialClosing\Models\AccountingPeriod;
use App\Domains\FinancialClosing\Repositories\Contracts\AccountingPeriodRepositoryInterface;
use Illuminate\Support\Facades\DB;
use Exception;
use RuntimeException;
use App\Domains\FinancialClosing\Events\AccountingPeriodClosed;

class CloseAccountingPeriodAction
{
    private AccountingPeriodRepositoryInterface $repository;

    public function __construct(AccountingPeriodRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $id, string $userId): AccountingPeriod
    {
        try {
            return DB::transaction(function () use ($id, $userId) {
                $period = $this->repository->findById($id);
                if (!$period) {
                    throw new RuntimeException("Accounting period not found.");
                }
                if (!in_array($period->status, ['Open', 'Reopened'])) {
                    throw new RuntimeException("Only Open or Reopened periods can be closed.");
                }

                $updatedPeriod = $this->repository->update($id, [
                    'status' => 'Closed',
                    'closed_by' => $userId,
                    'closed_at' => now(),
                    'updated_by' => $userId,
                ]);

                event(new AccountingPeriodClosed($updatedPeriod, $userId));

                return $updatedPeriod;
            });
        } catch (Exception $e) {
            throw $e;
        }
    }
}
