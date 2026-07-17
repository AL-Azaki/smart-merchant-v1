<?php

namespace App\Domains\Inventory\DTOs\Inventory;

class UpdateInventoryDTO
{
    public function __construct(
        public readonly ?float $alertQuantity = null
    ) {}

    public static function fromRequest(array $data): self
    {
        return new self(
            alertQuantity: isset($data['alert_quantity']) ? (float)$data['alert_quantity'] : null
        );
    }

    public function toArray(): array
    {
        $data = [];
        if ($this->alertQuantity !== null) $data['alert_quantity'] = $this->alertQuantity;
        return $data;
    }
}
