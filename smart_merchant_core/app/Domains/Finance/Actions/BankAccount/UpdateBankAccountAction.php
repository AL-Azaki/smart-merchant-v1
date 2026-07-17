<?php

namespace App\Domains\Finance\Actions\BankAccount;

use App\Domains\Finance\Models\BankAccount;
use App\Domains\Finance\Repositories\Contracts\BankAccountRepositoryInterface;
use Exception;

class UpdateBankAccountAction
{
    private BankAccountRepositoryInterface $repository;

    public function __construct(BankAccountRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $id, array $data): BankAccount
    {
        try {
            return $this->repository->update($id, $data);
        } catch (Exception $e) {
            throw $e;
        }
    }
}
