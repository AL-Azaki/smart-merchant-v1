<?php

namespace App\Domains\Finance\Http\Resources\CashRegister;

use Illuminate\Http\Resources\Json\ResourceCollection;

class CashRegisterCollection extends ResourceCollection
{
    public function toArray($request)
    {
        return [
            'data' => $this->collection,
        ];
    }
}
