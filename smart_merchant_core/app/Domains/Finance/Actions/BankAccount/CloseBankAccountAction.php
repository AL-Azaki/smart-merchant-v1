<?php

namespace App\Domains\Finance\Actions\BankAccount;

use App\Domains\Finance\Models\BankAccount;
use App\Domains\Finance\Repositories\Contracts\BankAccountRepositoryInterface;
use App\Domains\Finance\Events\Banking\BankAccountClosed;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
use Exception;

class CloseBankAccountAction
{
    private BankAccountRepositoryInterface $repository;

    public function __construct(BankAccountRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $id, array $data = []): BankAccount
    {
        try {
            return DB::transaction(function () use ($id, $data) {
                $account = $this->repository->update($id, array_merge($data, ['status' => 'Closed']));
                DB::afterCommit(fn() => Event::dispatch(new BankAccountClosed($account)));
                return $account;
            });
        } catch (Exception $e) {
            throw $e;
        }
    }
}
