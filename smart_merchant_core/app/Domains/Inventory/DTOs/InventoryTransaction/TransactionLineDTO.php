<?php

namespace App\Domains\Inventory\DTOs\InventoryTransaction;

class TransactionLineDTO
{
    public function __construct(
        public readonly string $productUnitId,
        public readonly float $quantity,
        public readonly float $unitCost = 0.00
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            productUnitId: $data['product_unit_id'],
            quantity: (float) $data['quantity'],
            unitCost: isset($data['unit_cost']) ? (float) $data['unit_cost'] : 0.00
        );
    }

    public function toArray(): array
    {
        return [
            'product_unit_id' => $this->productUnitId,
            'quantity' => $this->quantity,
            'unit_cost' => $this->unitCost,
        ];
    }
}
