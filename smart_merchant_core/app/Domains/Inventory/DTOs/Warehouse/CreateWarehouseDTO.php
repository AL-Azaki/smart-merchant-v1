<?php

namespace App\Domains\Inventory\DTOs\Warehouse;

class CreateWarehouseDTO
{
    public function __construct(
        public readonly string $businessId,
        public readonly string $branchId,
        public readonly string $warehouseName,
        public readonly string $warehouseCode,
        public readonly ?string $address = null,
        public readonly bool $isDefault = false,
        public readonly bool $isActive = true
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            businessId: $data['business_id'],
            branchId: $data['branch_id'],
            warehouseName: $data['warehouse_name'],
            warehouseCode: $data['warehouse_code'],
            address: $data['address'] ?? null,
            isDefault: filter_var($data['is_default'] ?? false, FILTER_VALIDATE_BOOLEAN),
            isActive: filter_var($data['is_active'] ?? true, FILTER_VALIDATE_BOOLEAN)
        );
    }

    public function toArray(): array
    {
        return [
            'business_id' => $this->businessId,
            'branch_id' => $this->branchId,
            'warehouse_name' => $this->warehouseName,
            'warehouse_code' => $this->warehouseCode,
            'address' => $this->address,
            'is_default' => $this->isDefault,
            'is_active' => $this->isActive,
        ];
    }
}
