<?php

namespace App\Domains\FinancialClosing\Actions;

use App\Domains\FinancialClosing\Models\AccountingPeriod;
use App\Domains\FinancialClosing\Repositories\Contracts\AccountingPeriodRepositoryInterface;
use Illuminate\Support\Facades\DB;
use Exception;

class CreateAccountingPeriodAction
{
    private AccountingPeriodRepositoryInterface $repository;

    public function __construct(AccountingPeriodRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(array $data): AccountingPeriod
    {
        try {
            return DB::transaction(function () use ($data) {
                $data['status'] = 'Open';
                return $this->repository->create($data);
            });
        } catch (Exception $e) {
            throw $e;
        }
    }
}
