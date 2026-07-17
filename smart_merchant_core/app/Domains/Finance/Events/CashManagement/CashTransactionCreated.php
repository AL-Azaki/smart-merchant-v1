<?php

namespace App\Domains\Finance\Events\CashManagement;

use App\Domains\Finance\Models\CashTransaction;

class CashTransactionCreated
{
    public CashTransaction $transaction;

    public function __construct(CashTransaction $transaction)
    {
        $this->transaction = $transaction;
    }
}
