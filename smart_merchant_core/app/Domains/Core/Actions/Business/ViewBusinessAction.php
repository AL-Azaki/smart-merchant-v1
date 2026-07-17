<?php

namespace App\Domains\Core\Actions\Business;

use App\Domains\Core\Models\Business;

class ViewBusinessAction
{
    public function handle(string $id): Business
    {
        return Business::findOrFail($id);
    }
}
