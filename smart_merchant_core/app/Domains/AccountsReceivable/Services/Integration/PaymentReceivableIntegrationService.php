<?php

namespace App\Domains\AccountsReceivable\Services\Integration;

use App\Domains\AccountsReceivable\Actions\RecordReceivableEntryAction;
use App\Domains\AccountsReceivable\Repositories\Contracts\CustomerReceivableRepositoryInterface;
use App\Domains\Finance\Models\Payment;
use RuntimeException;

class PaymentReceivableIntegrationService
{
    private CustomerReceivableRepositoryInterface $repository;
    private RecordReceivableEntryAction $recordEntryAction;

    public function __construct(
        CustomerReceivableRepositoryInterface $repository,
        RecordReceivableEntryAction $recordEntryAction
    ) {
        $this->repository = $repository;
        $this->recordEntryAction = $recordEntryAction;
    }

    public function handlePaymentAllocation(Payment $payment, string $customerId, float $allocatedAmount): void
    {
        $receivable = $this->repository->findByCustomer($payment->business_id, $customerId);

        if (! $receivable) {
            throw new RuntimeException("Cannot allocate payment: CustomerReceivable not found.");
        }

        $entryData = [
            'business_id' => $payment->business_id,
            'entry_type' => 'Payment',
            'direction' => 'Credit',
            'amount' => $allocatedAmount,
            'document_type' => get_class($payment),
            'document_id' => $payment->id,
            'created_by' => $payment->created_by,
        ];

        $this->recordEntryAction->execute($receivable->id, $entryData);
    }
}
