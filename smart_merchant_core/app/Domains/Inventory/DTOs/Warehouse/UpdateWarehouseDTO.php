<?php

namespace App\Domains\Inventory\DTOs\Warehouse;

class UpdateWarehouseDTO
{
    public function __construct(
        public readonly ?string $branchId = null,
        public readonly ?string $warehouseName = null,
        public readonly ?string $warehouseCode = null,
        public readonly ?string $address = null,
        public readonly ?bool $isDefault = null,
        public readonly ?bool $isActive = null
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            branchId: array_key_exists('branch_id', $data) ? $data['branch_id'] : null,
            warehouseName: array_key_exists('warehouse_name', $data) ? $data['warehouse_name'] : null,
            warehouseCode: array_key_exists('warehouse_code', $data) ? $data['warehouse_code'] : null,
            address: array_key_exists('address', $data) ? $data['address'] : null,
            isDefault: isset($data['is_default']) ? filter_var($data['is_default'], FILTER_VALIDATE_BOOLEAN) : null,
            isActive: isset($data['is_active']) ? filter_var($data['is_active'], FILTER_VALIDATE_BOOLEAN) : null
        );
    }

    public function toArray(): array
    {
        $data = [];
        if ($this->branchId !== null) $data['branch_id'] = $this->branchId;
        if ($this->warehouseName !== null) $data['warehouse_name'] = $this->warehouseName;
        if ($this->warehouseCode !== null) $data['warehouse_code'] = $this->warehouseCode;
        if ($this->address !== null) $data['address'] = $this->address;
        if ($this->isDefault !== null) $data['is_default'] = $this->isDefault;
        if ($this->isActive !== null) $data['is_active'] = $this->isActive;
        return $data;
    }
}
