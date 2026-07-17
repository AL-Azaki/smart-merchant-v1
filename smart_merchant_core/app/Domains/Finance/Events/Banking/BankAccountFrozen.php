<?php

namespace App\Domains\Finance\Events\Banking;

use App\Domains\Finance\Models\BankAccount;

class BankAccountFrozen
{
    public BankAccount $bankAccount;

    public function __construct(BankAccount $bankAccount)
    {
        $this->bankAccount = $bankAccount;
    }
}
