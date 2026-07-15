<?php

namespace App\Domains\Purchasing\Services\Integration;

use Illuminate\Support\Collection;

class PurchasingInventoryTransactionLinesBuilder
{
    public function build(Collection $items): array
    {
        $lines = [];
        foreach ($items as $index => $item) {
            $lines[] = [
                'business_id' => $item->business_id,
                'product_unit_id' => $item->product_unit_id,
                'line_number' => $index + 1,
                'quantity' => (float)$item->quantity,
                'unit_cost' => (float)$item->unit_price,
            ];
        }
        
        return $lines;
    }
}
