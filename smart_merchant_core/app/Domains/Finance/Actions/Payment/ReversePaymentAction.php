<?php

namespace App\Domains\Finance\Actions\Payment;

use App\Domains\Finance\Repositories\Contracts\PaymentRepositoryInterface;
use App\Domains\Finance\Models\Payment;
use App\Domains\Finance\Contracts\PostingEngineInterface;
use App\Domains\Finance\DTOs\PostingEngine\ReverseRequestDTO;
use App\Domains\Finance\Contracts\Integration\SalesSettlementInterface;
use App\Domains\Finance\Contracts\Integration\PurchasingSettlementInterface;
use App\Domains\Finance\Services\Payment\InvoiceSettlementBuilder;
use App\Domains\Finance\Events\Payment\PaymentReversed;
use Illuminate\Support\Facades\DB;
use Exception;
use InvalidArgumentException;

class ReversePaymentAction
{
    private PaymentRepositoryInterface $repository;
    private PostingEngineInterface $postingEngine;
    private SalesSettlementInterface $salesSettlement;
    private PurchasingSettlementInterface $purchasingSettlement;
    private InvoiceSettlementBuilder $settlementBuilder;

    public function __construct(
        PaymentRepositoryInterface $repository,
        PostingEngineInterface $postingEngine,
        SalesSettlementInterface $salesSettlement,
        PurchasingSettlementInterface $purchasingSettlement,
        InvoiceSettlementBuilder $settlementBuilder
    ) {
        $this->repository = $repository;
        $this->postingEngine = $postingEngine;
        $this->salesSettlement = $salesSettlement;
        $this->purchasingSettlement = $purchasingSettlement;
        $this->settlementBuilder = $settlementBuilder;
    }

    public function execute(string $id, string $userId, string $reason): Payment
    {
        try {
            $payment = DB::transaction(function () use ($id, $userId, $reason) {
                $payment = $this->repository->loadAggregate($id);

                if (!$payment) {
                    throw new Exception("Payment not found.");
                }

                if ($payment->status !== 'Posted') {
                    throw new InvalidArgumentException("Only Posted payments can be reversed.");
                }

                // Application Boundary: Orchestrates Domain Services.
                
                $data = [
                    'status' => 'Reversed',
                    'reversed_by' => $userId,
                    'reversed_at' => now(),
                    'reversal_reason' => $reason,
                ];

                $payment = $this->repository->update($id, $data);
                
                // For reversal, we need the original journal ID. Assuming it's resolved via a service or passed
                // we'll pass a dummy ID for the architecture implementation demo.
                $originalJournalId = '00000000-0000-0000-0000-000000000000';
                
                $reverseRequest = new ReverseRequestDTO(
                    originalJournalId: $originalJournalId,
                    postingDate: now()->format('Y-m-d'),
                    reversedBy: $userId,
                    description: $reason
                );
                
                $this->postingEngine->reverse($reverseRequest);

                // 2. Reverse Sales & Purchasing Settlement
                if ($payment->allocations && $payment->allocations->isNotEmpty()) {
                    foreach ($payment->allocations as $allocation) {
                        if ($allocation->document_type === 'SalesInvoice') {
                            $settlementRequest = $this->settlementBuilder->build($payment, $allocation, 'reverse');
                            $this->salesSettlement->reverse($settlementRequest);
                        } elseif ($allocation->document_type === 'PurchaseInvoice') {
                            $settlementRequest = $this->settlementBuilder->build($payment, $allocation, 'reverse');
                            $this->purchasingSettlement->reverse($settlementRequest);
                        }
                    }
                }

                return $payment;
            });

            event(new PaymentReversed($payment));

            return $payment;
        } catch (Exception $e) {
            throw $e;
        }
    }
}
