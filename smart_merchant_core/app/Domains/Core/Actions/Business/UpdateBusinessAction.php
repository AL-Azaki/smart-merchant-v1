<?php

namespace App\Domains\Core\Actions\Business;

use App\Domains\Core\Models\Business;

class UpdateBusinessAction
{
    public function handle(Business $business, array $data): Business
    {
        $business->update($data);
        return $business;
    }
}
