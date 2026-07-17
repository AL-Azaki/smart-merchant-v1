<?php

namespace App\Domains\Finance\Events\Banking;

use App\Domains\Finance\Models\BankAccount;

class BankAccountClosed
{
    public BankAccount $bankAccount;

    public function __construct(BankAccount $bankAccount)
    {
        $this->bankAccount = $bankAccount;
    }
}
