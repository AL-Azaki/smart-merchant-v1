<?php

namespace App\Domains\FinancialClosing\Actions;

use App\Domains\FinancialClosing\Models\AccountingPeriod;
use App\Domains\FinancialClosing\Repositories\Contracts\AccountingPeriodRepositoryInterface;
use Illuminate\Support\Facades\DB;
use Exception;
use RuntimeException;

class UpdateAccountingPeriodAction
{
    private AccountingPeriodRepositoryInterface $repository;

    public function __construct(AccountingPeriodRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $id, array $data): AccountingPeriod
    {
        try {
            return DB::transaction(function () use ($id, $data) {
                $period = $this->repository->findById($id);
                if (!$period) {
                    throw new RuntimeException("Accounting period not found.");
                }
                if ($period->status === 'Closed') {
                    throw new RuntimeException("Closed accounting periods cannot be updated.");
                }

                return $this->repository->update($id, $data);
            });
        } catch (Exception $e) {
            throw $e;
        }
    }
}
