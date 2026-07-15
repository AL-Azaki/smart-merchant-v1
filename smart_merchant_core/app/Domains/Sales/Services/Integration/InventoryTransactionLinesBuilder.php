<?php

namespace App\Domains\Sales\Services\Integration;

use Illuminate\Support\Collection;

class InventoryTransactionLinesBuilder
{
    public function build(Collection $items): array
    {
        $lines = [];
        $lineNumber = 1;
        
        foreach ($items as $item) {
            $lines[] = [
                'product_unit_id' => $item->product_unit_id,
                'line_number' => $lineNumber++,
                'quantity' => (float)$item->quantity,
                'unit_cost' => (float)($item->cost_price ?? 0),
            ];
        }

        return $lines;
    }
}
