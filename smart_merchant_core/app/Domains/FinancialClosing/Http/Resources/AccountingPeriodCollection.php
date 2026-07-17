<?php

namespace App\Domains\FinancialClosing\Http\Resources;

use Illuminate\Http\Resources\Json\ResourceCollection;

class AccountingPeriodCollection extends ResourceCollection
{
    public function toArray($request)
    {
        return [
            'data' => $this->collection,
        ];
    }
}
