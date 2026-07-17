<?php

namespace App\Domains\Finance\Services\Banking;

use App\Domains\Finance\Contracts\Integration\BankingCashIntegrationInterface;
use App\Domains\Finance\Contracts\PostingEngineInterface;
use App\Domains\Finance\Repositories\Contracts\BankAccountRepositoryInterface;
use App\Domains\Finance\Models\CashTransaction;

class BankingCashIntegrationService implements BankingCashIntegrationInterface
{
    private BankAccountRepositoryInterface $repository;
    private BankAccountResolver $accountResolver;
    private CashToBankTransactionBuilder $transactionBuilder;
    private BankPostingBuilder $postingBuilder;
    private PostingEngineInterface $postingEngine;

    public function __construct(
        BankAccountRepositoryInterface $repository,
        BankAccountResolver $accountResolver,
        CashToBankTransactionBuilder $transactionBuilder,
        BankPostingBuilder $postingBuilder,
        PostingEngineInterface $postingEngine
    ) {
        $this->repository = $repository;
        $this->accountResolver = $accountResolver;
        $this->transactionBuilder = $transactionBuilder;
        $this->postingBuilder = $postingBuilder;
        $this->postingEngine = $postingEngine;
    }

    public function handleCashDeposit(CashTransaction $cashTransaction, string $bankAccountId): void
    {
        $account = $this->accountResolver->resolve($bankAccountId, $cashTransaction->business_id);
        $transactionData = $this->transactionBuilder->buildDeposit($cashTransaction, $account->id);

        $bankTransaction = $this->repository->addTransaction($account->id, $transactionData);

        $postingRequest = $this->postingBuilder->build($bankTransaction);
        $this->postingEngine->post($postingRequest);
    }

    public function handleBankWithdrawal(string $bankAccountId, string $businessId, float $amount, ?string $createdBy): void
    {
        $account = $this->accountResolver->resolve($bankAccountId, $businessId);
        $transactionData = $this->transactionBuilder->buildWithdrawal($account->id, $businessId, $amount, $createdBy);

        $bankTransaction = $this->repository->addTransaction($account->id, $transactionData);

        $postingRequest = $this->postingBuilder->build($bankTransaction);
        $this->postingEngine->post($postingRequest);
    }
}
