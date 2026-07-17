<?php

namespace App\Domains\Finance\Actions\BankAccount;

use App\Domains\Finance\Models\BankAccount;
use App\Domains\Finance\Repositories\Contracts\BankAccountRepositoryInterface;
use Exception;

class CreateBankAccountAction
{
    private BankAccountRepositoryInterface $repository;

    public function __construct(BankAccountRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(array $data): BankAccount
    {
        try {
            return $this->repository->create($data);
        } catch (Exception $e) {
            throw $e;
        }
    }
}
