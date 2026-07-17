<?php

namespace App\Domains\Finance\Events\Banking;

use App\Domains\Finance\Models\BankTransaction;

class BankTransactionCreated
{
    public BankTransaction $transaction;

    public function __construct(BankTransaction $transaction)
    {
        $this->transaction = $transaction;
    }
}
