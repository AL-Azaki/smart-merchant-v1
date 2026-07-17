<?php

namespace App\Domains\Finance\Actions\CashRegister;

use App\Domains\Finance\Repositories\Contracts\CashRegisterRepositoryInterface;
use App\Domains\Finance\Contracts\PostingEngineInterface;
use App\Domains\Finance\Services\CashManagement\CashPostingBuilder;
use App\Domains\Finance\Events\CashManagement\CashTransactionCreated;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
use Exception;

class CreateCashTransactionAction
{
    private CashRegisterRepositoryInterface $repository;
    private PostingEngineInterface $postingEngine;
    private CashPostingBuilder $postingBuilder;

    public function __construct(
        CashRegisterRepositoryInterface $repository,
        PostingEngineInterface $postingEngine,
        CashPostingBuilder $postingBuilder
    ) {
        $this->repository = $repository;
        $this->postingEngine = $postingEngine;
        $this->postingBuilder = $postingBuilder;
    }

    public function execute(string $registerId, array $transactionData): void
    {
        try {
            DB::transaction(function () use ($registerId, $transactionData) {
                $transaction = $this->repository->addTransaction($registerId, $transactionData);
                
                $postingRequest = $this->postingBuilder->build($transaction);
                $this->postingEngine->post($postingRequest);

                DB::afterCommit(fn() => Event::dispatch(new CashTransactionCreated($transaction)));
            });
        } catch (Exception $e) {
            throw $e;
        }
    }
}
