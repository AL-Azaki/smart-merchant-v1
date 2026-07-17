<?php

namespace App\Domains\Finance\Actions\BankAccount;

use App\Domains\Finance\Repositories\Contracts\BankAccountRepositoryInterface;
use App\Domains\Finance\Contracts\PostingEngineInterface;
use App\Domains\Finance\Services\Banking\BankPostingBuilder;
use App\Domains\Finance\Events\Banking\BankTransactionCreated;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
use Exception;

class CreateBankTransactionAction
{
    private BankAccountRepositoryInterface $repository;
    private PostingEngineInterface $postingEngine;
    private BankPostingBuilder $postingBuilder;

    public function __construct(
        BankAccountRepositoryInterface $repository,
        PostingEngineInterface $postingEngine,
        BankPostingBuilder $postingBuilder
    ) {
        $this->repository = $repository;
        $this->postingEngine = $postingEngine;
        $this->postingBuilder = $postingBuilder;
    }

    public function execute(string $accountId, array $transactionData): void
    {
        try {
            DB::transaction(function () use ($accountId, $transactionData) {
                $transaction = $this->repository->addTransaction($accountId, $transactionData);

                $postingRequest = $this->postingBuilder->build($transaction);
                $this->postingEngine->post($postingRequest);

                DB::afterCommit(fn() => Event::dispatch(new BankTransactionCreated($transaction)));
            });
        } catch (Exception $e) {
            throw $e;
        }
    }
}
