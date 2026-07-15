<?php

namespace App\Domains\Finance\Services\Payment;

use App\Domains\Finance\Models\Payment;
use App\Domains\Finance\DTOs\PostingEngine\PostingRequestDTO;
use App\Domains\Finance\DTOs\PostingEngine\PostingLineDTO;
use App\Domains\Finance\Actions\AccountMapping\ResolveAccountMappingAction;

class PaymentPostingBuilder
{
    private ResolveAccountMappingAction $resolveMapping;

    public function __construct(ResolveAccountMappingAction $resolveMapping)
    {
        $this->resolveMapping = $resolveMapping;
    }

    public function build(Payment $payment, string $fiscalPeriodId): PostingRequestDTO
    {
        $lines = [];

        // The bank/cash side uses the payment's chart_of_account_id
        if (in_array($payment->payment_type, ['Receipt', 'Refund'])) {
            // Money in -> Debit Bank
            $lines[] = new PostingLineDTO(
                chartOfAccountId: $payment->chart_of_account_id,
                type: 'Debit',
                foreignAmount: (float) $payment->amount,
                baseAmount: (float) $payment->base_amount,
                description: $payment->notes ?? 'Payment Receipt'
            );
        } else {
            // Money out -> Credit Bank
            $lines[] = new PostingLineDTO(
                chartOfAccountId: $payment->chart_of_account_id,
                type: 'Credit',
                foreignAmount: (float) $payment->amount,
                baseAmount: (float) $payment->base_amount,
                description: $payment->notes ?? 'Payment Disbursement'
            );
        }

        // The offset side(s)
        if ($payment->allocations && $payment->allocations->isNotEmpty()) {
            foreach ($payment->allocations as $allocation) {
                $offsetMappingType = $this->determineMappingType($payment);
                $offsetAccount = $this->resolveMapping->execute($payment->business_id, $offsetMappingType);

                $allocationBaseAmount = $allocation->amount * clone $payment->exchange_rate;

                $type = in_array($payment->payment_type, ['Receipt', 'Refund']) ? 'Credit' : 'Debit';

                $lines[] = new PostingLineDTO(
                    chartOfAccountId: $offsetAccount->id,
                    type: $type,
                    foreignAmount: (float) $allocation->amount,
                    baseAmount: (float) $allocationBaseAmount,
                    description: "Allocation for {$allocation->document_type} {$allocation->document_id}"
                );
            }
        } else {
            // Unallocated payment (Advance Payment)
            $offsetMappingType = $this->determineUnallocatedMappingType($payment);
            $offsetAccount = $this->resolveMapping->execute($payment->business_id, $offsetMappingType);

            $type = in_array($payment->payment_type, ['Receipt', 'Refund']) ? 'Credit' : 'Debit';

            $lines[] = new PostingLineDTO(
                chartOfAccountId: $offsetAccount->id,
                type: $type,
                foreignAmount: (float) $payment->amount,
                baseAmount: (float) $payment->base_amount,
                description: 'Unallocated Payment'
            );
        }

        return new PostingRequestDTO(
            businessId: $payment->business_id,
            fiscalPeriodId: $fiscalPeriodId,
            documentDate: $payment->payment_date->format('Y-m-d H:i:s'),
            postingDate: now()->format('Y-m-d H:i:s'),
            journalType: 'Payment',
            documentType: 'Payment',
            documentId: $payment->id,
            documentNumber: $payment->payment_number,
            currencyId: $payment->currency_id,
            exchangeRate: (float) $payment->exchange_rate,
            description: $payment->notes ?? 'Payment Posting',
            createdBy: $payment->posted_by ?? $payment->created_by,
            lines: $lines
        );
    }

    private function determineMappingType(Payment $payment): string
    {
        if ($payment->contact_type === 'Customer') {
            return 'AccountsReceivable';
        } elseif ($payment->contact_type === 'Supplier') {
            return 'AccountsPayable';
        }
        
        return 'GeneralSuspense';
    }

    private function determineUnallocatedMappingType(Payment $payment): string
    {
        if ($payment->contact_type === 'Customer') {
            return 'AdvanceFromCustomers';
        } elseif ($payment->contact_type === 'Supplier') {
            return 'AdvanceToSuppliers';
        }

        return 'GeneralSuspense';
    }
}
