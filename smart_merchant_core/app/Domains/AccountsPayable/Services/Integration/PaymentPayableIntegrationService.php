<?php

namespace App\Domains\AccountsPayable\Services\Integration;

use App\Domains\AccountsPayable\Actions\RecordPayableEntryAction;
use App\Domains\AccountsPayable\Repositories\Contracts\SupplierPayableRepositoryInterface;
use App\Domains\Finance\Models\Payment;
use RuntimeException;

class PaymentPayableIntegrationService
{
    private SupplierPayableRepositoryInterface $repository;
    private RecordPayableEntryAction $recordEntryAction;

    public function __construct(
        SupplierPayableRepositoryInterface $repository,
        RecordPayableEntryAction $recordEntryAction
    ) {
        $this->repository = $repository;
        $this->recordEntryAction = $recordEntryAction;
    }

    public function handlePaymentAllocation(Payment $payment, string $supplierId, float $allocatedAmount): void
    {
        $payable = $this->repository->findBySupplier($payment->business_id, $supplierId);

        if (! $payable) {
            throw new RuntimeException("Cannot allocate payment: SupplierPayable not found.");
        }

        $entryData = [
            'business_id' => $payment->business_id,
            'entry_type' => 'Payment',
            'direction' => 'Debit',
            'amount' => $allocatedAmount,
            'document_type' => get_class($payment),
            'document_id' => $payment->id,
            'created_by' => $payment->created_by,
        ];

        $this->recordEntryAction->execute($payable->id, $entryData);
    }
}
