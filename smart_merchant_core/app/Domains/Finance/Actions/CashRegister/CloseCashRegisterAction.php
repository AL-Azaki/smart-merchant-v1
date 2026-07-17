<?php

namespace App\Domains\Finance\Actions\CashRegister;

use App\Domains\Finance\Repositories\Contracts\CashRegisterRepositoryInterface;
use App\Domains\Finance\Models\CashRegister;
use App\Domains\Finance\Events\CashManagement\CashRegisterClosed;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
use Exception;

class CloseCashRegisterAction
{
    private CashRegisterRepositoryInterface $repository;

    public function __construct(CashRegisterRepositoryInterface $repository)
    {
        $this->repository = $repository;
    }

    public function execute(string $id, array $data): CashRegister
    {
        try {
            return DB::transaction(function () use ($id, $data) {
                $register = $this->repository->update($id, array_merge($data, ['status' => 'Closed']));
                DB::afterCommit(fn() => Event::dispatch(new CashRegisterClosed($register)));
                return $register;
            });
        } catch (Exception $e) {
            throw $e;
        }
    }
}
