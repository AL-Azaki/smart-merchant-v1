<?php

namespace App\Domains\Inventory\DTOs\InventoryTransaction;

class UpdateTransactionDTO
{
    public function __construct(
        public readonly ?string $referenceType = null,
        public readonly ?string $referenceId = null,
        public readonly ?string $transactionDate = null
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            referenceType: array_key_exists('reference_type', $data) ? $data['reference_type'] : null,
            referenceId: array_key_exists('reference_id', $data) ? $data['reference_id'] : null,
            transactionDate: array_key_exists('transaction_date', $data) ? $data['transaction_date'] : null
        );
    }

    public function toArray(): array
    {
        $data = [];
        if ($this->referenceType !== null) $data['reference_type'] = $this->referenceType;
        if ($this->referenceId !== null) $data['reference_id'] = $this->referenceId;
        if ($this->transactionDate !== null) $data['transaction_date'] = $this->transactionDate;
        return $data;
    }
}
