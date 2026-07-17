<?php

namespace App\Domains\Inventory\Actions\Inventory;

use App\Domains\Inventory\DTOs\Inventory\UpdateInventoryDTO;
use App\Domains\Inventory\Models\Inventory;
use App\Domains\Inventory\Repositories\Contracts\InventoryRepositoryInterface;

class UpdateAlertQuantityAction
{
    public function __construct(private readonly UpdateInventoryAction $updateAction) {}

    public function handle(Inventory $inventory, float $alertQuantity): Inventory
    {
        $dto = new UpdateInventoryDTO(alertQuantity: $alertQuantity);
        return $this->updateAction->handle($inventory, $dto);
    }
}
