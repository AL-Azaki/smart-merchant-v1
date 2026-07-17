<?php

namespace App\Domains\AccountsPayable\Http\Resources;

use Illuminate\Http\Resources\Json\ResourceCollection;

class SupplierPayableCollection extends ResourceCollection
{
    public function toArray($request)
    {
        return [
            'data' => $this->collection,
        ];
    }
}
