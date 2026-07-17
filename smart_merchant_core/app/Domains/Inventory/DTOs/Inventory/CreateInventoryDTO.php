<?php

namespace App\Domains\Inventory\DTOs\Inventory;

class CreateInventoryDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly string $warehouseId,
        public readonly string $productUnitId,
        public readonly float $quantity = 0.000,
        public readonly float $averageCost = 0.00,
        public readonly float $alertQuantity = 0.000
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            businessId: $data['business_id'],
            warehouseId: $data['warehouse_id'],
            productUnitId: $data['product_unit_id'],
            quantity: isset($data['quantity']) ? (float)$data['quantity'] : 0.000,
            averageCost: isset($data['average_cost']) ? (float)$data['average_cost'] : 0.00,
            alertQuantity: isset($data['alert_quantity']) ? (float)$data['alert_quantity'] : 0.000
        );
    }

    public function toArray(): array
    {
        return [
            'business_id' => $this->businessId,
            'warehouse_id' => $this->warehouseId,
            'product_unit_id' => $this->productUnitId,
            'quantity' => $this->quantity,
            'average_cost' => $this->averageCost,
            'alert_quantity' => $this->alertQuantity,
        ];
    }
}
