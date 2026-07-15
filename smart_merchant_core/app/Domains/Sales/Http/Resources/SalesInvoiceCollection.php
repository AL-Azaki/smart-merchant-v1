<?php

namespace App\Domains\Sales\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\ResourceCollection;

class SalesInvoiceCollection extends ResourceCollection
{
    public function toArray(Request $request): array
    {
        return [
            'data' => $this->collection,
            'meta' => [
                'total_count' => $this->collection->count(),
            ],
        ];
    }
}
