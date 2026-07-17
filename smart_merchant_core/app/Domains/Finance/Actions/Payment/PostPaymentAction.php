<?php

namespace App\Domains\Finance\Actions\Payment;

use App\Domains\Finance\Repositories\Contracts\PaymentRepositoryInterface;
use App\Domains\Finance\Models\Payment;
use App\Domains\Finance\Contracts\PostingEngineInterface;
use App\Domains\Finance\Services\Payment\PaymentPostingBuilder;
use App\Domains\Finance\Contracts\Integration\SalesSettlementInterface;
use App\Domains\Finance\Contracts\Integration\PurchasingSettlementInterface;
use App\Domains\Finance\Services\Payment\InvoiceSettlementBuilder;
use App\Domains\Finance\Events\Payment\PaymentPosted;
use Illuminate\Support\Facades\DB;
use Exception;
use InvalidArgumentException;

class PostPaymentAction
{
    private PaymentRepositoryInterface $repository;
    private PostingEngineInterface $postingEngine;
    private PaymentPostingBuilder $postingBuilder;
    private SalesSettlementInterface $salesSettlement;
    private PurchasingSettlementInterface $purchasingSettlement;
    private InvoiceSettlementBuilder $settlementBuilder;

    public function __construct(
        PaymentRepositoryInterface $repository,
        PostingEngineInterface $postingEngine,
        PaymentPostingBuilder $postingBuilder,
        SalesSettlementInterface $salesSettlement,
        PurchasingSettlementInterface $purchasingSettlement,
        InvoiceSettlementBuilder $settlementBuilder
    ) {
        $this->repository = $repository;
        $this->postingEngine = $postingEngine;
        $this->postingBuilder = $postingBuilder;
        $this->salesSettlement = $salesSettlement;
        $this->purchasingSettlement = $purchasingSettlement;
        $this->settlementBuilder = $settlementBuilder;
    }

    public function execute(string $id, string $userId): Payment
    {
        try {
            $payment = DB::transaction(function () use ($id, $userId) {
                $payment = $this->repository->loadAggregate($id);

                if (!$payment) {
                    throw new Exception("Payment not found.");
                }

                if ($payment->status !== 'Draft') {
                    throw new InvalidArgumentException("Only Draft payments can be posted.");
                }

                // Application Boundary: Orchestrates Domain Services.
                // Assuming fiscal period resolution handled elsewhere, we pass a dummy or resolve it
                $fiscalPeriodId = '00000000-0000-0000-0000-000000000000';
                
                $data = [
                    'status' => 'Posted',
                    'posted_by' => $userId,
                    'posted_at' => now(),
                ];

                $payment = $this->repository->update($id, $data);
                
                // 1. Accounting Posting
                $postingRequest = $this->postingBuilder->build($payment, $fiscalPeriodId);
                $this->postingEngine->post($postingRequest);

                // 2. Sales & Purchasing Settlement
                if ($payment->allocations && $payment->allocations->isNotEmpty()) {
                    foreach ($payment->allocations as $allocation) {
                        if ($allocation->document_type === 'SalesInvoice') {
                            $settlementRequest = $this->settlementBuilder->build($payment, $allocation, 'settle');
                            $this->salesSettlement->settle($settlementRequest);
                        } elseif ($allocation->document_type === 'PurchaseInvoice') {
                            $settlementRequest = $this->settlementBuilder->build($payment, $allocation, 'settle');
                            $this->purchasingSettlement->settle($settlementRequest);
                        }
                    }
                }

                return $payment;
            });

            event(new PaymentPosted($payment));

            return $payment;
        } catch (Exception $e) {
            throw $e;
        }
    }
}
