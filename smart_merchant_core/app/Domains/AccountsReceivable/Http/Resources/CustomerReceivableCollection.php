<?php

namespace App\Domains\AccountsReceivable\Http\Resources;

use Illuminate\Http\Resources\Json\ResourceCollection;

class CustomerReceivableCollection extends ResourceCollection
{
    public function toArray($request)
    {
        return [
            'data' => $this->collection,
        ];
    }
}
