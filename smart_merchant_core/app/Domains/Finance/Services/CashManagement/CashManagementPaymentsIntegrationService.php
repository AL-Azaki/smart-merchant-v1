<?php

namespace App\Domains\Finance\Services\CashManagement;

use App\Domains\Finance\Contracts\Integration\CashManagementIntegrationInterface;
use App\Domains\Finance\Repositories\Contracts\CashRegisterRepositoryInterface;
use App\Domains\Finance\Contracts\PostingEngineInterface;
use App\Domains\Finance\Models\Payment;

class CashManagementPaymentsIntegrationService implements CashManagementIntegrationInterface
{
    private CashRegisterRepositoryInterface $registerRepository;
    private PaymentCashTransactionBuilder $transactionBuilder;
    private CashRegisterResolver $registerResolver;
    private CashPostingBuilder $postingBuilder;
    private PostingEngineInterface $postingEngine;

    public function __construct(
        CashRegisterRepositoryInterface $registerRepository,
        PaymentCashTransactionBuilder $transactionBuilder,
        CashRegisterResolver $registerResolver,
        CashPostingBuilder $postingBuilder,
        PostingEngineInterface $postingEngine
    ) {
        $this->registerRepository = $registerRepository;
        $this->transactionBuilder = $transactionBuilder;
        $this->registerResolver = $registerResolver;
        $this->postingBuilder = $postingBuilder;
        $this->postingEngine = $postingEngine;
    }

    /**
     * Handles the full Cash transaction lifecycle for an approved cash payment.
     * This is called from inside the Payments Domain's transaction boundary.
     */
    public function handlePaymentCashTransaction(Payment $payment): void
    {
        $registerId = $this->resolveRegisterForPayment($payment);
        $transactionData = $this->transactionBuilder->build($payment);

        $transaction = $this->registerRepository->addTransaction($registerId, $transactionData);

        $postingRequest = $this->postingBuilder->build($transaction);
        $this->postingEngine->post($postingRequest);
    }

    /**
     * Handles the full Cash reversal lifecycle for a reversed cash payment.
     * This is called from inside the Payments Domain's transaction boundary.
     */
    public function handlePaymentReversalCashTransaction(Payment $payment): void
    {
        $registerId = $this->resolveRegisterForPayment($payment);
        $transactionData = $this->transactionBuilder->buildReversal($payment);

        $transaction = $this->registerRepository->addTransaction($registerId, $transactionData);

        $postingRequest = $this->postingBuilder->build($transaction);
        $this->postingEngine->post($postingRequest);
    }

    /**
     * Resolves the correct register ID for a payment.
     */
    public function resolveRegisterForPayment(Payment $payment): string
    {
        return $this->registerResolver->resolveForPayment($payment);
    }
}
