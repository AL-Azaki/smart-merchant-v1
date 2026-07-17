<?php

namespace App\Domains\Finance\Services\Banking;

use App\Domains\Finance\Contracts\Integration\BankingPaymentsIntegrationInterface;
use App\Domains\Finance\Contracts\PostingEngineInterface;
use App\Domains\Finance\Repositories\Contracts\BankAccountRepositoryInterface;
use App\Domains\Finance\Models\Payment;

class BankingPaymentsIntegrationService implements BankingPaymentsIntegrationInterface
{
    private BankAccountRepositoryInterface $repository;
    private PaymentBankTransactionBuilder $transactionBuilder;
    private BankAccountResolver $accountResolver;
    private BankPostingBuilder $postingBuilder;
    private PostingEngineInterface $postingEngine;

    public function __construct(
        BankAccountRepositoryInterface $repository,
        PaymentBankTransactionBuilder $transactionBuilder,
        BankAccountResolver $accountResolver,
        BankPostingBuilder $postingBuilder,
        PostingEngineInterface $postingEngine
    ) {
        $this->repository = $repository;
        $this->transactionBuilder = $transactionBuilder;
        $this->accountResolver = $accountResolver;
        $this->postingBuilder = $postingBuilder;
        $this->postingEngine = $postingEngine;
    }

    public function handlePaymentBankTransaction(Payment $payment): void
    {
        $accountId = $this->resolveAccountForPayment($payment);
        $transactionData = $this->transactionBuilder->build($payment);

        $transaction = $this->repository->addTransaction($accountId, $transactionData);

        $postingRequest = $this->postingBuilder->build($transaction);
        $this->postingEngine->post($postingRequest);
    }

    public function handlePaymentReversalBankTransaction(Payment $payment): void
    {
        $accountId = $this->resolveAccountForPayment($payment);
        $transactionData = $this->transactionBuilder->buildReversal($payment);

        $transaction = $this->repository->addTransaction($accountId, $transactionData);

        $postingRequest = $this->postingBuilder->build($transaction);
        $this->postingEngine->post($postingRequest);
    }

    public function resolveAccountForPayment(Payment $payment): string
    {
        $account = $this->accountResolver->resolve($payment->bank_account_id, $payment->business_id);
        return $account->id;
    }
}
