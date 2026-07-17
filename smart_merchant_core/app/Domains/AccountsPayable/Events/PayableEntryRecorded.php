<?php

namespace App\Domains\AccountsPayable\Events;

use App\Domains\AccountsPayable\Models\PayableEntry;

class PayableEntryRecorded
{
    public PayableEntry $entry;

    public function __construct(PayableEntry $entry)
    {
        $this->entry = $entry;
    }
}
